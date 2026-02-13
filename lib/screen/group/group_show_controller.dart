import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:smart_kids_app_end/const/api_const.dart';

class GroupShowController extends GetxController {
  final int id;
  GroupShowController({required this.id});

  // Holatlar
  var isLoading = true.obs;
  var isKidsLoading = false.obs;
  var isUsersLoading = false.obs;
  var isUpdating = false.obs;
  var isNoactiveLoading = false.obs;
  var isTeachersLoading = false.obs;

  // Individual Loading (Tugma darajasida)
  var deletingIds = <int>[].obs;
  var addingKidIds = <int>[].obs;
  var addingTeacherIds = <int>[].obs;

  // Ma'lumotlar
  var groupData = {}.obs;
  var groupKids = <dynamic>[].obs;
  var groupUsers = <dynamic>[].obs;
  var noactiveKids = <dynamic>[].obs;
  var filteredNoactiveKids = <dynamic>[].obs;
  var availableTeachers = <dynamic>[].obs;
  var filteredTeachers = <dynamic>[].obs;

  final box = GetStorage();
  final lang = GetStorage().read('lang') ?? 'uz';

  @override
  void onInit() {
    super.onInit();
    fetchGroupDetails();
  }

  // API So'rovlari
  Future<void> fetchGroupDetails() async {
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('${ApiConst.apiUrl}/group/show/$id'),
        headers: {'Authorization': 'Bearer ${box.read('token')}', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) groupData.value = jsonDecode(response.body)['data'];
    } finally { isLoading.value = false; }
  }

  Future<void> fetchAvailableTeachers() async {
    isTeachersLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('${ApiConst.apiUrl}/emploes/all/tarbiyachi/$id'),
        headers: {'Authorization': 'Bearer ${box.read('token')}', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body)['users'];
        availableTeachers.value = data;
        filteredTeachers.value = data;
      }
    } finally { isTeachersLoading.value = false; }
  }

  Future<void> fetchNoactiveKids() async {
    isNoactiveLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('${ApiConst.apiUrl}/kids/isactive'),
        headers: {'Authorization': 'Bearer ${box.read('token')}', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        noactiveKids.value = data;
        filteredNoactiveKids.value = data;
      }
    } finally { isNoactiveLoading.value = false; }
  }

  Future<void> addTeacherToGroup(int teacherId) async {
    addingTeacherIds.add(teacherId);
    try {
      final response = await http.post(
        Uri.parse('${ApiConst.apiUrl}/group/add/user'),
        headers: {'Authorization': 'Bearer ${box.read('token')}', 'Content-Type': 'application/json'},
        body: jsonEncode({"group_id": id, "user_id": teacherId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        fetchGroupDetails();
        fetchGroupUsers();
        _showSuccess(lang == 'uz' ? "Tarbiyachi biriktirildi" : "Воспитатель прикреплен");
      }
    } finally { addingTeacherIds.remove(teacherId); }
  }

  Future<void> addKidToGroup(int kidId) async {
    addingKidIds.add(kidId);
    try {
      final response = await http.post(
        Uri.parse('${ApiConst.apiUrl}/group/add/kids'),
        headers: {'Authorization': 'Bearer ${box.read('token')}', 'Content-Type': 'application/json'},
        body: jsonEncode({"group_id": id, "kids_id": kidId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        fetchGroupDetails();
        fetchGroupKids();
        _showSuccess(lang == 'uz' ? "Bola qo'shildi" : "Ребенок добавлен");
      }
    } finally { addingKidIds.remove(kidId); }
  }

  Future<void> removeFromGroup(int historyId, bool isKid) async {
    deletingIds.add(historyId);
    String endpoint = isKid ? 'delete/kids' : 'delete/user';
    try {
      final response = await http.post(
        Uri.parse('${ApiConst.apiUrl}/group/$endpoint/$historyId'),
        headers: {'Authorization': 'Bearer ${box.read('token')}', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        fetchGroupDetails();
        isKid ? fetchGroupKids() : fetchGroupUsers();
        _showSuccess(lang == 'uz' ? "Muvaffaqiyatli o'chirildi" : "Успешно удалено");
      }
    } finally { deletingIds.remove(historyId); }
  }

  Future<void> updateGroup(String name, String desc, String amount) async {
    isUpdating.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConst.apiUrl}/group/update/$id'),
        headers: {'Authorization': 'Bearer ${box.read('token')}', 'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "description": desc,
          "amount": int.tryParse(amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        }),
      );
      if (response.statusCode == 200) { Get.back(); fetchGroupDetails(); }
    } finally { isUpdating.value = false; }
  }

  // Yordamchi metodlar
  void _showSuccess(String msg) {
    Get.snackbar("OK", msg, backgroundColor: Colors.white,borderColor: Colors.green,borderWidth: 0.5, colorText: Colors.black54, snackPosition: SnackPosition.TOP);
  }

  void searchTeacher(String q) => filteredTeachers.value = availableTeachers.where((t) => t['name'].toString().toLowerCase().contains(q.toLowerCase())).toList();
  void searchNoactiveKid(String q) => filteredNoactiveKids.value = noactiveKids.where((k) => k['full_name'].toString().toLowerCase().contains(q.toLowerCase())).toList();

  Future<void> fetchGroupKids() async {
    isKidsLoading.value = true;
    try {
      final r = await http.get(Uri.parse('${ApiConst.apiUrl}/group/kids/$id'), headers: {'Authorization': 'Bearer ${box.read('token')}'});
      if (r.statusCode == 200) groupKids.value = jsonDecode(r.body)['data'];
    } finally { isKidsLoading.value = false; }
  }

  Future<void> fetchGroupUsers() async {
    isUsersLoading.value = true;
    try {
      final r = await http.get(Uri.parse('${ApiConst.apiUrl}/group/users/$id'), headers: {'Authorization': 'Bearer ${box.read('token')}'});
      if (r.statusCode == 200) groupUsers.value = jsonDecode(r.body)['data'];
    } finally { isUsersLoading.value = false; }
  }
}