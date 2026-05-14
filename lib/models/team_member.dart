enum MemberRole { participant, mentor }

class TeamMember {
  final String id;
  final String name;
  final MemberRole role;

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
  });
}