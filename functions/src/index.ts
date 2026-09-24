import * as dotenv from "dotenv";
import * as path from "path";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

// Load root secrets.env if present (for local emulation and test runs)
dotenv.config({ path: path.resolve(__dirname, "../../secrets.env") });
dotenv.config({ path: path.resolve(__dirname, "../.secret.local") });

const b2KeyId = defineSecret("B2_KEY_ID");
const b2ApplicationKey = defineSecret("B2_APPLICATION_KEY");
const b2BucketName = defineSecret("B2_BUCKET_NAME");
const b2BucketId = defineSecret("B2_BUCKET_ID");
const b2Endpoint = defineSecret("B2_ENDPOINT");

/**
 * Generates a presigned PUT URL for Backblaze B2 S3-compatible object storage.
 * Restricted to authenticated users; prefixes upload key with `providers/{uid}/nic/`.
 */
export const getB2UploadUrl = onCall(
  {
    secrets: [b2KeyId, b2ApplicationKey, b2BucketName, b2BucketId, b2Endpoint],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    const { fileName, contentType } = (request.data || {}) as {
      fileName?: string;
      contentType?: string;
    };

    if (
      !fileName ||
      typeof fileName !== "string" ||
      !contentType ||
      typeof contentType !== "string"
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Both 'fileName' and 'contentType' must be provided as non-empty strings."
      );
    }

    const uid = request.auth.uid;
    const sanitizedFileName = fileName.replace(/[^a-zA-Z0-9._-]/g, "_");
    const fileKey = `providers/${uid}/nic/${Date.now()}-${sanitizedFileName}`;

    const endpointVal = b2Endpoint.value();
    const endpoint = endpointVal.startsWith("http")
      ? endpointVal
      : `https://${endpointVal}`;

    const s3Client = new S3Client({
      endpoint,
      region: "us-east-005",
      credentials: {
        accessKeyId: b2KeyId.value(),
        secretAccessKey: b2ApplicationKey.value(),
      },
    });

    const command = new PutObjectCommand({
      Bucket: b2BucketName.value(),
      Key: fileKey,
      ContentType: contentType,
    });

    // Presigned PUT URL valid for 10 minutes (600 seconds)
    const uploadUrl = await getSignedUrl(s3Client, command, { expiresIn: 600 });

    return {
      uploadUrl,
      fileKey,
    };
  }
);
