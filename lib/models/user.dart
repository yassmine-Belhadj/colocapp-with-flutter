class User {
  int? id;
  String name;
  String email;
  String password;
  int? groupId;
  bool isAdmin;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.groupId,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'groupId': groupId,
      'isAdmin': isAdmin ? 1 : 0,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      groupId: map['groupId'],
      isAdmin: map['isAdmin'] == 1,
    );
  }
}