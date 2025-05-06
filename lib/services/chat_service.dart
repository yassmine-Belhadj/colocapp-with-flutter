import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../models/message.dart';
import '../models/user.dart';
import 'database_service.dart';

class ChatService {
  final DatabaseService _databaseService;
  final ImagePicker _picker = ImagePicker();

  ChatService({required DatabaseService databaseService})
      : _databaseService = databaseService;

  Future<void> initialize() async {
    final db = await _databaseService.database;
    // Tables are now created in database_service
  }

  Future<File?> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}${extension(pickedFile.path)}';
        final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
        return savedImage;
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
      rethrow;
    }
    return null;
  }

  Future<File?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'file_${DateTime.now().millisecondsSinceEpoch}${extension(result.files.single.path!)}';
        final savedFile = await File(result.files.single.path!).copy('${appDir.path}/$fileName');
        return savedFile;
      }
    } catch (e) {
      debugPrint('File picker error: $e');
      rethrow;
    }
    return null;
  }

  Future<Message> sendMessage({
    required int groupId,
    required int senderId,
    required String content,
    String? filePath,
    bool isImage = false,
  }) async {
    final db = await _databaseService.database;
    final message = Message(
      groupId: groupId,
      senderId: senderId,
      content: content,
      sentAt: DateTime.now(),
      filePath: filePath,
      isImage: isImage,
    );

    try {
      final id = await db.insert('messages', message.toMap());
      return message.copyWith(id: id);
    } catch (e) {
      debugPrint('Error saving message: $e');
      rethrow;
    }
  }

  Future<List<Message>> getMessagesForGroup(int groupId) async {
    final db = await _databaseService.database;
    final maps = await db.rawQuery('''
      SELECT messages.*, users.name as senderName 
      FROM messages
      JOIN users ON messages.senderId = users.id
      WHERE messages.groupId = ?
      ORDER BY messages.sentAt DESC
    ''', [groupId]);

    return maps.map((map) => Message.fromMap(map)).toList();
  }

  Stream<List<Message>> streamMessagesForGroup(int groupId) {
    return Stream.periodic(const Duration(seconds: 1))
        .asyncMap((_) => getMessagesForGroup(groupId));
  }
}

extension MessageExtension on Message {
  Message copyWith({
    int? id,
    int? groupId,
    int? senderId,
    String? content,
    DateTime? sentAt,
    String? senderName,
    String? filePath,
    bool? isImage,
  }) {
    return Message(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      senderName: senderName ?? this.senderName,
      filePath: filePath ?? this.filePath,
      isImage: isImage ?? this.isImage,
    );
  }
}