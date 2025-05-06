class Message {
  final int? id;
  final int groupId;
  final int senderId;
  final String content;
  final DateTime sentAt;
  final String? senderName;
  final String? filePath;
  final bool isImage;

  Message({
    this.id,
    required this.groupId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.senderName,
    this.filePath,
    this.isImage = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'senderId': senderId,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'filePath': filePath,
      'isImage': isImage ? 1 : 0,
    };
  }

  static Message fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      groupId: map['groupId'],
      senderId: map['senderId'],
      content: map['content'],
      sentAt: DateTime.parse(map['sentAt']),
      senderName: map['senderName'],
      filePath: map['filePath'],
      isImage: map['isImage'] == 1,
    );
  }
}