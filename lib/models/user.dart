class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String level;        // например "Новичок", "Продвинутый"
  final int activeProjectsCount;
  final int completedProjectsCount;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.level,
    required this.activeProjectsCount,
    required this.completedProjectsCount,
  });

  String get fullName => '$firstName $lastName';
}