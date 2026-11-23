class Project {
  const Project({
    required this.id,
    required this.teamId,
    required this.key,
    required this.name,
    this.description = '',
    this.archived = false,
  });

  final String id;
  final String teamId;

  /// The short uppercase code, for example MOB.
  final String key;
  final String name;
  final String description;
  final bool archived;
}
