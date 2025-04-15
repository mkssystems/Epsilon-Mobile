class GameCharacter {
  final String id;
  final String name;
  final String type;
  final String age;
  final String role;
  final String portraitPath;
  final String backstoryPath;
  final String scenario;

  GameCharacter({
    required this.id,
    required this.name,
    required this.type,
    required this.age,
    required this.role,
    required this.portraitPath,
    required this.backstoryPath,
    required this.scenario,
  });

  factory GameCharacter.fromJson(Map<String, dynamic> json) {
    return GameCharacter(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      age: json['age'],
      role: json['role'],
      portraitPath: json['portrait_path'],
      backstoryPath: json['backstory_path'],
      scenario: json['scenario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'age': age,
      'role': role,
      'portrait_path': portraitPath,
      'backstory_path': backstoryPath,
      'scenario': scenario,
    };
  }
}
