class Group {
  int? id;
  String name;
  String description;
  int adminId; // ID of the user who created the group
  DateTime createdAt;

  Group({
    this.id,
    required this.name,
    required this.description,
    required this.adminId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'adminId': adminId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static Group fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      adminId: map['adminId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}