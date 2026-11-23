class Team {
  const Team({
    required this.id,
    required this.name,
    this.description = '',
    this.memberCount = 0,
  });

  final String id;
  final String name;
  final String description;
  final int memberCount;
}
