import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:smart_kids_app_end/const/api_const.dart';
import 'package:smart_kids_app_end/screen/xodim/xodim_show_page.dart';

// --- CONTROLLER ---
class XodimController extends GetxController {
  var isLoading = true.obs;
  var isSaving = false.obs;
  var allEmployees = <dynamic>[].obs;
  var filteredEmployees = <dynamic>[].obs;

  final box = GetStorage();
  final lang = GetStorage().read('lang') ?? 'uz';
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    isLoading.value = true;
    String? token = box.read('token');
    try {
      final response = await http.get(
        Uri.parse('${ApiConst.apiUrl}/emploes/all'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        allEmployees.value = decoded['data'] ?? [];
        filteredEmployees.value = allEmployees;
      }
    } catch (e) {
      debugPrint("Xodim API Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createEmployee(Map<String, dynamic> data) async {
    isSaving.value = true;
    String? token = box.read('token');
    try {
      final response = await http.post(
        Uri.parse('${ApiConst.apiUrl}/emploes/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        fetchEmployees();
        Get.snackbar(
            lang == 'uz' ? "Muvaffaqiyatli" : "Успешно",
            lang == 'uz' ? "Xodim muvaffaqiyatli qo'shildi" : "Сотрудник успешно добавлен",
            backgroundColor: Colors.green, colorText: Colors.white
        );
      } else {
        var res = jsonDecode(response.body);
        Get.snackbar(
            lang == 'uz' ? "Xatolik" : "Ошибка",
            res['message'] ?? (lang == 'uz' ? "Xato yuz berdi" : "Произошла ошибка"),
            backgroundColor: Colors.redAccent, colorText: Colors.white
        );
      }
    } catch (e) {
      Get.snackbar(lang == 'uz' ? "Xatolik" : "Ошибка", e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  void filterSearch(String query) {
    if (query.isEmpty) {
      filteredEmployees.value = allEmployees;
    } else {
      filteredEmployees.value = allEmployees.where((emp) {
        return emp['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
            emp['phone'].toString().contains(query);
      }).toList();
    }
  }
}

// --- UI PAGE ---
class XodimPage extends StatelessWidget {
  const XodimPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(XodimController());
    final f = NumberFormat("#,###", "uz_UZ");
    final lang = controller.lang;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
            lang == 'uz' ? "Xodimlar" : "Сотрудники",
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
              onPressed: () => _showAddEmployeeModal(context, controller, lang),
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.blue, size: 28)
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBox(controller, lang),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.allEmployees.isEmpty) {
                return const Center(child: SpinKitFadingFour(color: Colors.blue, size: 40));
              }
              if (controller.filteredEmployees.isEmpty) return _buildEmptyState(lang);
              return RefreshIndicator(
                onRefresh: () => controller.fetchEmployees(),
                color: Colors.blue,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: controller.filteredEmployees.length,
                  itemBuilder: (context, index) => _buildEmployeeCard(controller.filteredEmployees[index], f, lang),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- HODIM KARTASI ---
  Widget _buildEmployeeCard(dynamic emp, NumberFormat f, String lang) {
    Color typeColor;
    String typeStr = emp['type'].toString().toLowerCase();
    switch (typeStr) {
      case 'admin': typeColor = Colors.redAccent; break;
      case 'manager': typeColor = Colors.blueAccent; break;
      case 'tarbiyachi': typeColor = Colors.purpleAccent; break;
      case 'oshpaz': typeColor = Colors.orangeAccent; break;
      default: typeColor = Colors.teal;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => Get.to(() => XodimShowPage(id: emp['id'])),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.withOpacity(0.1),
                backgroundImage: NetworkImage(emp['image']),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        emp['name'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))
                    ),
                    const SizedBox(height: 4),
                    Text(
                        emp['phone'] ?? '-',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600)
                    ),
                    const SizedBox(height: 4),
                    Text(
                        "${f.format(emp['salary_amount'] ?? 0)} UZS",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  emp['type'].toString().toUpperCase(),
                  style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- QIDIRUV ---
  Widget _buildSearchBox(XodimController controller, String lang) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
    child: TextField(
      controller: controller.searchController,
      onChanged: controller.filterSearch,
      decoration: InputDecoration(
        hintText: lang == 'uz' ? "Ism yoki telefon..." : "Имя или телефон...",
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.blue),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: EdgeInsets.zero,
      ),
    ),
  );

  // --- QO'SHISH MODALI ---
  void _showAddEmployeeModal(BuildContext context, XodimController controller, String lang) {
    final formKey = GlobalKey<FormState>();
    final nameC = TextEditingController();
    final salaryC = TextEditingController();
    final passportSeriesC = TextEditingController();
    final passportNumberC = TextEditingController();
    final birthDateC = TextEditingController();
    final FocusNode passportNumberFocus = FocusNode();
    final phoneFormatter = MaskTextInputFormatter(mask: '## ### ####', filter: {"#": RegExp(r'[0-9]')});

    DateTime selectedDate = DateTime(2000, 1, 1);
    birthDateC.text = DateFormat('yyyy-MM-dd').format(selectedDate);

    String selectedType = 'hodim';
    final List<String> types = ['admin', 'manager', 'tarbiyachi', 'oshpaz', 'hodim'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Text(
                      lang == 'uz' ? "Yangi xodim qo'shish" : "Добавить нового сотрудника",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 25),

                  _fieldLabel(lang == 'uz' ? "F.I.SH" : "Ф.И.О"),
                  TextFormField(
                      controller: nameC,
                      decoration: _inputDeco(lang == 'uz' ? "Ismni kiriting" : "Введите Ф.И.О"),
                      validator: (v) => v!.isEmpty ? "!" : null
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel(lang == 'uz' ? "Telefon" : "Телефон"),
                  TextFormField(
                    keyboardType: TextInputType.phone,
                    inputFormatters: [phoneFormatter],
                    decoration: _inputDeco("90 123 4567").copyWith(
                      prefixIcon: const Padding(padding: EdgeInsets.all(12), child: Text("998 ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                    validator: (v) => phoneFormatter.getUnmaskedText().length < 9 ? "!" : null,
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel(lang == 'uz' ? "Pasport seriyasi va raqami" : "Серия и номер паспорта"),
                  Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: TextFormField(
                          controller: passportSeriesC,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [LengthLimitingTextInputFormatter(2), FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')), UpperCaseTextFormatter()],
                          decoration: _inputDeco("AA"),
                          onChanged: (v) { if (v.length == 2) FocusScope.of(context).requestFocus(passportNumberFocus); },
                          validator: (v) => v!.length < 2 ? "!" : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: passportNumberC,
                          focusNode: passportNumberFocus,
                          keyboardType: TextInputType.number,
                          inputFormatters: [LengthLimitingTextInputFormatter(7), FilteringTextInputFormatter.digitsOnly],
                          decoration: _inputDeco("1234567"),
                          validator: (v) => v!.length < 7 ? "!" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel(lang == 'uz' ? "Oylik maoshi" : "Ежемесячная зарплата"),
                  TextFormField(
                      controller: salaryC,
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco("0"),
                      validator: (v) => v!.isEmpty ? "!" : null
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel(lang == 'uz' ? "Tug'ilgan sanasi" : "Дата рождения"),
                  TextFormField(
                    controller: birthDateC, readOnly: true,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(1950), lastDate: DateTime.now());
                      if (picked != null) {
                        setModalState(() { selectedDate = picked; birthDateC.text = DateFormat('yyyy-MM-dd').format(selectedDate); });
                      }
                    },
                    decoration: _inputDeco("yyyy-mm-dd").copyWith(suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.blue)),
                    validator: (v) => v!.isEmpty ? "!" : null,
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel(lang == 'uz' ? "Lavozimi" : "Должность"),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                              value: selectedType, isExpanded: true,
                              items: types.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                              onChanged: (v) => setModalState(() => selectedType = v!)
                          )
                      )
                  ),
                  const SizedBox(height: 30),

                  Obx(() => controller.isSaving.value
                      ? const Center(child: SpinKitThreeBounce(color: Colors.blue, size: 30))
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        controller.createEmployee({
                          "name": nameC.text,
                          "phone": "998${phoneFormatter.getUnmaskedText()}",
                          "salary_amount": int.parse(salaryC.text),
                          "birth": birthDateC.text,
                          "series": "${passportSeriesC.text}${passportNumberC.text}".toUpperCase(),
                          "type": selectedType,
                        });
                      }
                    },
                    child: Text(
                        lang == 'uz' ? "SAQLASH" : "СОХРАНИТЬ",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  )),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // --- YORDAMCHI WIDGETLAR ---
  Widget _fieldLabel(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)
  );

  Widget _buildEmptyState(String lang) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.person_search_rounded, size: 60, color: Colors.grey.shade300),
      const SizedBox(height: 10),
      Text(
          lang == 'uz' ? "Xodimlar topilmadi" : "Сотрудники не найдены",
          style: const TextStyle(color: Colors.grey)
      ),
    ],
  ));
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}