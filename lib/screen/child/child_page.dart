import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:smart_kids_app_end/const/api_const.dart';
import 'package:smart_kids_app_end/screen/child/child_show_page.dart';

class KidController extends GetxController {
  var isLoading = false.obs;
  var isCreating = false.obs;
  var kidsList = <dynamic>[].obs;
  var filteredKidsList = <dynamic>[].obs;
  var selectedTab = 0.obs;

  final TextEditingController searchController = TextEditingController();
  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    fetchKids();
  }

  Future<void> fetchKids() async {
    isLoading.value = true;
    if (searchController.text.isEmpty) filteredKidsList.clear();

    String? token = box.read('token');
    String url = '${ApiConst.apiUrl}/kids/all';
    if (selectedTab.value == 1) url = '${ApiConst.apiUrl}/kids/active';
    if (selectedTab.value == 2) url = '${ApiConst.apiUrl}/kids/isactive';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List decodedData = jsonDecode(response.body);
        kidsList.value = decodedData;
        filteredKidsList.value = decodedData;
        searchKids(searchController.text);
      }
    } catch (e) {
      Get.snackbar(
        box.read('lang') == 'uz' ? "Xatolik" : "Ошибка",
        box.read('lang') == 'uz' ? "Ma'lumot yuklashda xatolik" : "Ошибка при загрузке данных",
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createKid(Map<String, dynamic> data) async {
    isCreating.value = true;
    String? token = box.read('token');
    try {
      final response = await http.post(
        Uri.parse('${ApiConst.apiUrl}/kids/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        fetchKids();
        Get.snackbar(
          box.read('lang') == 'uz' ? "Muvaffaqiyatli" : "Успешно",
          box.read('lang') == 'uz' ? "Yangi bola qo'shildi" : "Новый ребенок добавлен",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        final error = jsonDecode(response.body);
        Get.snackbar(
          box.read('lang') == 'uz' ? "Xatolik" : "Ошибка",
          error['message'] ?? (box.read('lang') == 'uz' ? "Xatolik yuz berdi" : "Произошла ошибка"),
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        box.read('lang') == 'uz' ? "Xatolik" : "Ошибка",
        box.read('lang') == 'uz' ? "Server bilan aloqa yo'q" : "Нет связи с сервером",
      );
    } finally {
      isCreating.value = false;
    }
  }

  void searchKids(String query) {
    if (query.isEmpty) {
      filteredKidsList.value = kidsList;
    } else {
      filteredKidsList.value = kidsList.where((kid) {
        final name = kid['full_name']?.toString().toLowerCase() ?? '';
        final series = kid['document_series']?.toString().toLowerCase() ?? '';
        return name.contains(query.toLowerCase()) || series.contains(query.toLowerCase());
      }).toList();
    }
  }

  void changeTab(int index) {
    if (selectedTab.value == index) return;
    selectedTab.value = index;
    fetchKids();
  }
}

// --- UI PAGE ---
class ChildPage extends StatelessWidget {
  const ChildPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(KidController());
    final lang = GetStorage().read('lang') ?? 'uz';

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == 'uz' ? "Bolalar" : "Дети"),
        actions: [
          IconButton(
            onPressed: () => _showAddKidModal(context, controller, lang),
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.blue, size: 20),
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(controller, lang),
          _buildSearchBox(controller, lang),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: SpinKitThreeBounce(color: Colors.blue, size: 30));
              }
              return RefreshIndicator(
                onRefresh: () => controller.fetchKids(),
                child: controller.filteredKidsList.isEmpty
                    ? ListView(children: [
                  SizedBox(height: Get.height * 0.2),
                  Center(child: Text(lang == 'uz' ? "Topilmadi" : "Не найдено"))
                ])
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.filteredKidsList.length,
                  itemBuilder: (context, index) => _buildKidCard(controller.filteredKidsList[index], lang),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(KidController controller, String lang) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Obx(() => Row(
        children: List.generate(3, (i) {
          final labels = lang == 'uz' ? ["Barchasi", "Aktiv", "Noaktiv"] : ["Все", "Актив", "Неактив"];
          bool isSel = controller.selectedTab.value == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.changeTab(i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? Colors.blue : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(labels[i], style: TextStyle(color: isSel ? Colors.white : Colors.black54, fontWeight: FontWeight.bold))),
              ),
            ),
          );
        }),
      )),
    );
  }

  Widget _buildSearchBox(KidController controller, String lang) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.searchKids,
        decoration: InputDecoration(
          hintText: lang == 'uz' ? "Ism yoki hujjat..." : "Поиск по имени или документу...",
          prefixIcon: const Icon(Icons.search, color: Colors.blue, size: 20),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildKidCard(dynamic kid, String lang) {
    final bool isActive = kid['is_active'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () {
          Get.to(() => ChildShowPage(id: kid['id']));
          print("Tanlangan bola ID: ${kid['id']}");
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: kid['photo_path'] ?? "",
            width: 55,
            height: 55,
            fit: BoxFit.cover,
            errorWidget: (c, u, e) => const Icon(Icons.person, size: 40, color: Colors.grey),
          ),
        ),
        title: Text(kid['full_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "${lang == 'uz' ? 'Hujjat' : 'Док.'}: ${kid['document_series']}\n"
              "${NumberFormat("#,###").format(kid['balance'])} UZS",
          style: const TextStyle(fontSize: 13),
        ),
        trailing: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  void _showAddKidModal(BuildContext context, KidController controller, String lang) {
    final formKey = GlobalKey<FormState>();
    final nameC = TextEditingController();
    final docSeriesC = TextEditingController();
    final docNumberC = TextEditingController();
    final guardianC = TextEditingController();
    final phoneC = TextEditingController();
    final addressC = TextEditingController();
    final bioC = TextEditingController();
    String selectedDate = "";

    final phoneMask = MaskTextInputFormatter(mask: '## ### ####', filter: {"#": RegExp(r'[0-9]')});

    Get.bottomSheet(
      DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Form(
              key: formKey,
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Text(
                      lang == 'uz' ? "Yangi bola qo'shish" : "Добавление ребенка",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _input(nameC, lang == 'uz' ? "F.I.SH" : "Ф.И.О"),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: docSeriesC,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[A-Z]')),
                              LengthLimitingTextInputFormatter(3),
                            ],
                            decoration: InputDecoration(
                              labelText: lang == 'uz' ? "Seriya" : "Серия",
                              hintText: "AA",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => v!.isEmpty ? "!" : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 5,
                          child: TextFormField(
                            controller: docNumberC,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                            ],
                            decoration: InputDecoration(
                              labelText: lang == 'uz' ? "Hujjat raqami" : "Номер документа",
                              hintText: "1234567",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => v!.isEmpty ? "!" : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _input(guardianC, lang == 'uz' ? "Vasiy ismi" : "Имя опекуна"),

                  _input(phoneC, lang == 'uz' ? "Telefon raqami" : "Номер телефона",
                      type: TextInputType.phone,
                      prefix: "+998 ",
                      formatters: [phoneMask]
                  ),

                  _input(addressC, lang == 'uz' ? "Manzil" : "Адрес"),
                  _input(bioC, lang == 'uz' ? "Biografiya" : "Биография", lines: 2),

                  StatefulBuilder(builder: (context, setDateState) => InkWell(
                    onTap: () async {
                      DateTime? p = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2021),
                          firstDate: DateTime(2010),
                          lastDate: DateTime.now()
                      );
                      if (p != null) setDateState(() => selectedDate = DateFormat('yyyy-MM-dd').format(p));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate.isEmpty
                                ? (lang == 'uz' ? "Tug'ilgan sana" : "Дата рождения")
                                : selectedDate,
                            style: TextStyle(color: selectedDate.isEmpty ? Colors.grey.shade600 : Colors.black),
                          ),
                          const Icon(Icons.calendar_month, color: Colors.blue),
                        ],
                      ),
                    ),
                  )),

                  const SizedBox(height: 20),
                  Obx(() => controller.isCreating.value
                      ? const SpinKitThreeBounce(color: Colors.blue, size: 30)
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: () {
                      if (formKey.currentState!.validate() && selectedDate.isNotEmpty) {
                        String fullDoc = "${docSeriesC.text.trim()}-${docNumberC.text.trim()}";
                        controller.createKid({
                          "full_name": nameC.text.trim(),
                          "document_series": fullDoc,
                          "guardian_name": guardianC.text.trim(),
                          "guardian_phone": "+998${phoneC.text.replaceAll(' ', '')}",
                          "address": addressC.text.trim(),
                          "biography": bioC.text.trim(),
                          "birth_date": selectedDate,
                        });
                      } else if (selectedDate.isEmpty) {
                        Get.snackbar(
                          lang == 'uz' ? "Sana" : "Дата",
                          lang == 'uz' ? "Tug'ilgan sanani tanlang" : "Выберите дату рождения",
                        );
                      }
                    },
                    child: Text(
                      lang == 'uz' ? "Saqlash" : "Сохранить",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  )),
                  const SizedBox(height: 350),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Widget _input(TextEditingController c, String l, {TextInputType type = TextInputType.text, int lines = 1, String? prefix, List<TextInputFormatter>? formatters}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
        controller: c,
        keyboardType: type,
        maxLines: lines,
        inputFormatters: formatters,
        decoration: InputDecoration(
            labelText: l,
            prefixText: prefix,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
        ),
        validator: (v) {
          if (v == null || v.isEmpty) {
            return GetStorage().read('lang') == 'uz' ? "To'ldiring" : "Заполните";
          }
          return null;
        }
    ),
  );
}