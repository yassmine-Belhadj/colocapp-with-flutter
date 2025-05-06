class Task {
  int? id;
  String description;
  int groupId;
  int assignedTo; // User ID
  int assignedBy; // User ID (admin)
  bool isCompleted;
  DateTime createdAt;
  DateTime? completedAt;

  Task({
    this.id,
    required this.description,
    required this.groupId,
    required this.assignedTo,
    required this.assignedBy,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'groupId': groupId,
      'assignedTo': assignedTo,
      'assignedBy': assignedBy,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  static Task fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      description: map['description'],
      groupId: map['groupId'],
      assignedTo: map['assignedTo'],
      assignedBy: map['assignedBy'],
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
    );
  }

  Task copyWith({
    int? id,
    String? description,
    int? groupId,
    int? assignedTo,
    int? assignedBy,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      description: description ?? this.description,
      groupId: groupId ?? this.groupId,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedBy: assignedBy ?? this.assignedBy,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}