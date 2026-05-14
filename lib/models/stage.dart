class Stage {
  final String id;
  final String title;
  final DateTime? dueDate;
  final int orderIndex;

  Stage({
    required this.id,
    required this.title,
    this.dueDate,
    required this.orderIndex,
  });
}