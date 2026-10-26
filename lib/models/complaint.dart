import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String id;
  final String
      type; // 'help' | 'report_user' | 'booking_problem' | 'payment_dispute' | 'account' | 'app_problem'
  final String reporterUid;
  final String reporterRole; // 'customer' | 'provider'
  final String? reporterName;
  final String? reportedUid;
  final String? reportedRole;
  final String? reportedName;
  final String? bookingId;
  final String subject;
  final String description;
  final List<String> photos;
  final String
      status; // 'open' | 'in_progress' | 'waiting_user' | 'resolved' | 'closed'
  final String? assignedAdminId;
  final String? resolutionNote;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastMessageAt;
  final DateTime? adminLastReadAt;

  // Legacy backwards compatibility fields
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String providerId;
  final String providerName;
  final String providerTrade;
  final String reason;
  final String? adminNotes;
  final String? accusedRole;

  const Complaint({
    this.id = '',
    this.type = 'help',
    this.reporterUid = '',
    this.reporterRole = 'customer',
    this.reporterName,
    this.reportedUid,
    this.reportedRole,
    this.reportedName,
    this.bookingId,
    this.subject = '',
    this.description = '',
    this.photos = const [],
    this.status = 'open',
    this.assignedAdminId,
    this.resolutionNote,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
    this.lastMessageAt,
    this.adminLastReadAt,
    this.customerId = '',
    this.customerName = '',
    this.customerPhone = '',
    this.providerId = '',
    this.providerName = '',
    this.providerTrade = '',
    this.reason = '',
    this.adminNotes,
    this.accusedRole,
  });

  String get effectiveReporterUid =>
      reporterUid.isNotEmpty ? reporterUid : customerId;
  String get effectiveReportedUid => reportedUid ?? providerId;
  String get effectiveSubject => subject.isNotEmpty ? subject : reason;
  String get effectiveType => type.isNotEmpty ? type : 'report_user';
  String get effectiveReporterName =>
      (reporterName != null && reporterName!.isNotEmpty)
          ? reporterName!
          : (customerName.isNotEmpty ? customerName : 'User');
  String get effectiveReportedName =>
      (reportedName != null && reportedName!.isNotEmpty)
          ? reportedName!
          : (providerName.isNotEmpty ? providerName : '');

  String get effectiveReportedRole =>
      (reportedRole != null && reportedRole!.isNotEmpty)
          ? reportedRole!
          : (accusedRole ?? '');

  bool get isOpen => status == 'open' || status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isWaitingUser => status == 'waiting_user';
  bool get isResolved => status == 'resolved';
  bool get isClosed => status == 'closed';

  // true if user sent a newer reply
  bool get hasNewUserReply =>
      lastMessageAt != null &&
      (adminLastReadAt == null || lastMessageAt!.isAfter(adminLastReadAt!));

  Map<String, dynamic> toMap() => {
        'type': type,
        'reporterUid': effectiveReporterUid,
        'reporterRole': reporterRole,
        if (reporterName != null && reporterName!.isNotEmpty)
          'reporterName': reporterName,
        if (effectiveReportedUid.isNotEmpty)
          'reportedUid': effectiveReportedUid,
        if (effectiveReportedRole.isNotEmpty)
          'reportedRole': effectiveReportedRole,
        if (effectiveReportedName.isNotEmpty)
          'reportedName': effectiveReportedName,
        if (bookingId != null && bookingId!.isNotEmpty) 'bookingId': bookingId,
        'subject': effectiveSubject,
        'description': description,
        'photos': photos,
        'status': status,
        if (assignedAdminId != null && assignedAdminId!.isNotEmpty)
          'assignedAdminId': assignedAdminId,
        if (resolutionNote != null && resolutionNote!.isNotEmpty)
          'resolutionNote': resolutionNote,
        if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': updatedAt != null
            ? Timestamp.fromDate(updatedAt!)
            : FieldValue.serverTimestamp(),
        'lastMessageAt': lastMessageAt != null
            ? Timestamp.fromDate(lastMessageAt!)
            : FieldValue.serverTimestamp(),
        if (adminLastReadAt != null)
          'adminLastReadAt': Timestamp.fromDate(adminLastReadAt!),
      };

  factory Complaint.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    final rawPhotos = map['photos'];
    final photoList = (rawPhotos is List)
        ? rawPhotos.map((e) => e.toString()).toList()
        : <String>[];

    final rUid =
        map['reporterUid']?.toString() ?? map['customerId']?.toString() ?? '';
    final rRole = map['reporterRole']?.toString() ?? 'customer';
    final targetUid =
        map['reportedUid']?.toString() ?? map['providerId']?.toString();

    return Complaint(
      id: id,
      type: map['type']?.toString() ?? 'report_user',
      reporterUid: rUid,
      reporterRole: rRole,
      reporterName:
          map['reporterName']?.toString() ?? map['customerName']?.toString(),
      reportedUid: targetUid,
      reportedRole:
          map['reportedRole']?.toString() ?? map['accusedRole']?.toString(),
      reportedName:
          map['reportedName']?.toString() ?? map['providerName']?.toString(),
      bookingId: map['bookingId']?.toString(),
      subject: map['subject']?.toString() ?? map['reason']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      photos: photoList,
      status: map['status']?.toString() ?? 'open',
      assignedAdminId: map['assignedAdminId']?.toString(),
      resolutionNote:
          map['resolutionNote']?.toString() ?? map['adminNotes']?.toString(),
      resolvedAt: parseDate(map['resolvedAt']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      lastMessageAt: parseDate(map['lastMessageAt']),
      adminLastReadAt: parseDate(map['adminLastReadAt']),
      customerId: map['customerId']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      customerPhone: map['customerPhone']?.toString() ?? '',
      providerId: map['providerId']?.toString() ?? '',
      providerName: map['providerName']?.toString() ?? '',
      providerTrade: map['providerTrade']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      adminNotes: map['adminNotes']?.toString(),
      accusedRole: map['accusedRole']?.toString(),
    );
  }
}
