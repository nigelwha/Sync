class Project {
  final String id;
  final String title;
  final String tags;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  String status;      // 'в работе' или 'завершён'
  String grade;       // 'не оценено', 'плохо', 'удовлетворительно', 'хорошо', 'отлично'

  Project({
    required this.id,
    required this.title,
    required this.tags,
    this.description,
    this.startDate,
    this.endDate,
    this.status = 'в работе',
    this.grade = 'не оценено',
  });
}