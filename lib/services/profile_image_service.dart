import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

// process profile picture
Uint8List _processProfileImage(Uint8List rawBytes) {
  final image = img.decodeImage(rawBytes);
  if (image == null) {
    throw Exception('Failed to decode the selected image.');
  }

  // crop to square
  final minDim = image.width < image.height ? image.width : image.height;
  final x = (image.width - minDim) ~/ 2;
  final y = (image.height - minDim) ~/ 2;

  final cropped = img.copyCrop(
    image,
    x: x,
    y: y,
    width: minDim,
    height: minDim,
  );

  // resize image
  final resized = img.copyResize(
    cropped,
    width: 400,
    height: 400,
    interpolation: img.Interpolation.linear,
  );

  // compress image
  const targetMaxBytes = 150000;
  final qualitySteps = [75, 65, 55, 45, 35, 25];

  Uint8List? result;
  for (final quality in qualitySteps) {
    final encoded = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    if (encoded.lengthInBytes <= targetMaxBytes) {
      result = encoded;
      break;
    }
  }

  if (result == null) {
    // lower quality if still too large
    final fallback = Uint8List.fromList(img.encodeJpg(resized, quality: 20));
    if (fallback.lengthInBytes <= targetMaxBytes) {
      result = fallback;
    } else {
      throw Exception('Image is too complex to compress under 150 KB. Please choose a simpler photo.');
    }
  }

  return result;
}

class ProfileImageService {
  static final ProfileImageService _instance = ProfileImageService._internal();
  factory ProfileImageService() => _instance;
  ProfileImageService._internal();

  final ImagePicker _picker = ImagePicker();
  final Map<String, Uint8List?> _cache = {};
  final Map<String, Stream<Uint8List?>> _streamCache = {};

  // get cached image
  Uint8List? getCachedImage(String uid) => _cache[uid];
  bool hasInCache(String uid) => _cache.containsKey(uid);

  // load image from cache or firestore
  Future<Uint8List?> getImage(String uid) async {
    if (uid.isEmpty) return null;
    if (_cache.containsKey(uid)) {
      return _cache[uid];
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('profileImages')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final raw = doc.data()!['data'];
        if (raw is Blob) {
          _cache[uid] = raw.bytes;
          return raw.bytes;
        }
      }
    } catch (_) {}

    _cache[uid] = null;
    return null;
  }

  // listen to image changes
  Stream<Uint8List?> watchImage(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    if (_streamCache.containsKey(uid)) {
      return _streamCache[uid]!;
    }

    final stream = FirebaseFirestore.instance
        .collection('profileImages')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final raw = snapshot.data()!['data'];
        if (raw is Blob) {
          _cache[uid] = raw.bytes;
          return raw.bytes;
        }
      }
      _cache[uid] = null;
      return null;
    }).asBroadcastStream();

    _streamCache[uid] = stream;
    return stream;
  }

  // pick and save new avatar
  Future<Uint8List?> pickAndUpload(ImageSource source) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('You must be signed in to upload a profile picture.');
    }

    // open camera or gallery
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null) return null;

    final rawBytes = await pickedFile.readAsBytes();

    // compress image
    final compressedBytes = await compute(_processProfileImage, rawBytes);

    // save to firestore
    await FirebaseFirestore.instance.collection('profileImages').doc(uid).set({
      'data': Blob(compressedBytes),
      'contentType': 'image/jpeg',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // save to memory cache
    _cache[uid] = compressedBytes;

    return compressedBytes;
  }

  // remove profile picture
  Future<void> remove({String? targetUid}) async {
    final uid = targetUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('profileImages')
        .doc(uid)
        .delete();

    _cache[uid] = null;
  }

  // clear memory cache
  void clearCache() {
    _cache.clear();
    _streamCache.clear();
  }
}
