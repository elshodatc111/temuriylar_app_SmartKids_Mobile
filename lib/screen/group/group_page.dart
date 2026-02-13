import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:smart_kids_app_end/const/api_const.dart';
import 'package:smart_kids_app_end/screen/group/group_show_page.dart';

// --- CONTROLLER ---
class GroupController extends GetxController {
  var isLoading = false.obs;
  var isCreating = false.obs;
  var groupsList = <dynamic>[].obs;
  var filteredGroups = <dynamic>[].obs;

  final TextEditingController searchController = TextEditingController();
  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    isLoading.value = true;
    String? token = box.read('token');
    try {
      final response = await http.get(
        Uri.parse('${ApiConst.apiUrl}/group/all'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        groupsList.value = data['groups'] ?? [];
        filteredGroups.value = data['groups'] ?? [];
      }
    } catch (e) {
      Get.snackbar(
          box.read('lang') == 'uz' ? "Xatolik" : "Ошибка",
          box.read('lang') == 'uz' ? "Server bilan aloqa uzildi" : "Связь с сервером прервана"
      );
    } finally {
      isLoading.value = false;
    }
  }

  void searchGroup(String query) {
    if (query.isEmpty) {
      filteredGroups.value = groupsList;
    } else {
      filteredGroups.value = groupsList.where((g) {
        final name = g['name'].toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    }
  }

  Future<void> createGroup(String name, String desc, String amount) async {
    isCreating.value = true;
    String? token = box.read('token');
    final lang = box.read('lang') ?? 'uz';
    try {
      final response = await http.post(
        Uri.parse('${ApiConst.apiUrl}/group/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "name": name,
          "description": desc,
          "amount": int.parse(amount.replaceAll(RegExp(r'[^0-9]'), '')),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        fetchGroups();
        Get.snackbar(
          lang == 'uz' ? "Muvaffaqiyatli" : "Успешно",
          lang == 'uz' ? "Guruh yaratildi" : "Группа создана",
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      }
    } catch (e) {
      Get.snackbar(
          lang == 'uz' ? "Xatolik" : "Ошибка",
          lang == 'uz' ? "Ma'lumot yuborishda xatolik" : "Ошибка при отправке данных"
      );
    } finally {
      isCreating.value = false;
    }
  }
}

// --- UI PAGE ---
class GroupPage extends StatelessWidget {
  const GroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GroupController());
    final lang = GetStorage().read('lang') ?? 'uz';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          lang == 'uz' ? "Guruhlar" : "Группы",
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _showAddGroupModal(context, controller, lang),
              icon: const Icon(Icons.add_home_work_rounded, color: Colors.blue, size: 22),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchBox(controller, lang),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: SpinKitFadingFour(color: Colors.blue, size: 40));
              }
              return RefreshIndicator(
                onRefresh: () => controller.fetchGroups(),
                color: Colors.blue,
                child: controller.filteredGroups.isEmpty
                    ? _buildEmptyState(lang)
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: controller.filteredGroups.length,
                  itemBuilder: (context, index) => _buildGroupCard(controller.filteredGroups[index], lang),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(GroupController controller, String lang) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.searchGroup,
        decoration: InputDecoration(
          hintText: lang == 'uz' ? "Guruh qidirish..." : "Поиск группы...",
          hintStyle: const TextStyle(color: Colors.blueGrey, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.blueGrey, size: 20),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildGroupCard(dynamic group, String lang) {
    final currencyFormat = NumberFormat("#,###", "uz_UZ");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.to(() => GroupShowPage(id: group['id'])),
            child: Stack(
              children: [
                Positioned(
                  left: 0, top: 0, bottom: 0,
                  child: Container(width: 5, color: Colors.blue.shade400),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              group['name'] ?? '-',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${currencyFormat.format(group['amount'])} UZS",
                              style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _statsChip(Icons.child_care_rounded, "${group['count_kids']}", Colors.orange.shade600),
                          const SizedBox(width: 12),
                          _statsChip(Icons.school_rounded, "${group['count_users']}", Colors.indigo.shade400),
                          const Spacer(),
                          Text(
                            lang == 'uz' ? "Batafsil" : "Подробнее",
                            style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.blue, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statsChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            lang == 'uz' ? "Guruhlar topilmadi" : "Группы не найдены",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          ),
        ],
      ),
    );
  }

  void _showAddGroupModal(BuildContext context, GroupController controller, String lang) {
    final formKey = GlobalKey<FormState>();
    final nameC = TextEditingController();
    final descC = TextEditingController();
    final amountC = TextEditingController();

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 45, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Text(
                    lang == 'uz' ? "Yangi guruh yaratish" : "Создание новой группы",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 20),
                _modernInput(
                    nameC,
                    lang == 'uz' ? "Guruh nomi" : "Название группы",
                    Icons.label_important_outline,
                    lang
                ),
                _modernInput(
                    descC,
                    lang == 'uz' ? "Tavsif" : "Описание",
                    Icons.notes_rounded,
                    lang,
                    lines: 2
                ),
                _modernInput(
                    amountC,
                    lang == 'uz' ? "Oylik to'lov summasi" : "Сумма ежемесячной оплаты",
                    Icons.payments_outlined,
                    lang,
                    type: TextInputType.number
                ),
                const SizedBox(height: 24),
                Obx(() => controller.isCreating.value
                    ? const Center(child: SpinKitThreeBounce(color: Colors.blue, size: 30))
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      controller.createGroup(nameC.text, descC.text, amountC.text);
                    }
                  },
                  child: Text(
                      lang == 'uz' ? "Saqlash" : "Сохранить",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                )),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernInput(TextEditingController c, String l, IconData icon, String lang, {TextInputType type = TextInputType.text, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: l,
          prefixIcon: Icon(icon, size: 20, color: Colors.blue.shade400),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
        validator: (v) => v!.isEmpty ? (lang == 'uz' ? "Maydonni to'ldiring" : "Заполните поле") : null,
      ),
    );
  }
}