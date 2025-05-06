import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/group_service.dart';

class GroupProvider with ChangeNotifier {
  final GroupService _groupService = GroupService();
  List<Group> _groups = [];
  Group? _currentGroup;

  List<Group> get groups => _groups;
  Group? get currentGroup => _currentGroup;

  Future<void> loadGroups() async {
    _groups = await _groupService.getAllGroups();
    notifyListeners();
  }

  Future<List<Group>> getGroupsForUser(int userId) async {
    return await _groupService.getGroupsByMemberId(userId);
  }

  Future<Group> createGroup(String name, String description, int adminId) async {
    final group = await _groupService.createGroup(name, description, adminId);
    _groups.add(group);
    _currentGroup = group;
    notifyListeners();
    return group;
  }

  Future<void> updateGroup(Group group) async {
    await _groupService.updateGroup(group);
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = group;
    }
    if (_currentGroup?.id == group.id) {
      _currentGroup = group;
    }
    notifyListeners();
  }

  Future<void> deleteGroup(int id) async {
    await _groupService.deleteGroup(id);
    _groups.removeWhere((group) => group.id == id);
    if (_currentGroup?.id == id) {
      _currentGroup = null;
    }
    notifyListeners();
  }

  Future<void> setCurrentGroup(Group? group) async {
    _currentGroup = group;
    notifyListeners();
  }
}