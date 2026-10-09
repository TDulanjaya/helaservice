class JobStatus {
  JobStatus._();

  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String enRoute = 'en_route';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String declined = 'declined';
  static const String expired = 'expired';

  static bool isTerminal(String status) =>
      status == completed || status == cancelled || status == declined || status == expired;

  static bool canCancel(String status) =>
      status == pending || status == confirmed || status == enRoute;

  static bool isActive(String status) =>
      status == confirmed || status == enRoute || status == inProgress;
}

class JobRequestStatus {
  JobRequestStatus._();

  static const String open = 'open';
  static const String pendingProvider = 'pending_provider';
  static const String assigned = 'assigned';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String expired = 'expired';

  static bool isTerminal(String status) =>
      status == completed || status == cancelled || status == expired;
}
