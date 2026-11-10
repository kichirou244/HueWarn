class AlertNotification {
  final String id;
  final String title;
  final String message;
  final String severity;
  final String createdAt;

  const AlertNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
  });

  factory AlertNotification.fromJson(Map<String, dynamic> json) {
    return AlertNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
