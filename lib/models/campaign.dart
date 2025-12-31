class Campaign {
  final String id;
  final String title;
  final String status; // Active, Paused, Draft, Completed
  final String audience;
  final int called;
  final int target;
  final DateTime startDate;
  final DateTime dueDate;

  Campaign({
    required this.id,
    required this.title,
    required this.status,
    required this.audience,
    required this.called,
    required this.target,
    required this.startDate,
    required this.dueDate,
  });

  double get progress => target == 0 ? 0 : called / target;
}
