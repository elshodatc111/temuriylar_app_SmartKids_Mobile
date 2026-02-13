import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_kids_app_end/const/api_const.dart';
import 'package:intl/intl.dart';
import 'package:smart_kids_app_end/screen/my_groups/my_group_davomad_create_page.dart';
import 'package:smart_kids_app_end/screen/my_groups/my_group_davomad_history_page.dart';
import 'package:url_launcher/url_launcher.dart';

// --- CONTROLLER ---
class MyGroupShowController extends GetxController {
  final int groupId;
  MyGroupShowController(this.groupId);

  var isLoading = true.obs;
  var groupData = {}.obs;
  var kidsList = <dynamic>[].obs;
  var staffList = <dynamic>[].obs;
  final box = GetStorage();

  String get lang => box.read('lang') ?? 'uz';
  String t(String uz, String ru) => lang == 'uz' ? uz : ru;

  @override
  void onInit() {
    fetchGroupDetails();
    super.onInit();
  }

  Future<void> fetchGroupDetails() async {
    try {
      isLoading(true);
      String token = box.read('token') ?? '';
      var response = await http.get(
        Uri.parse('${ApiConst.apiUrl}/kid/tarbiyachi/groups/show/$groupId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse != null && jsonResponse['status'] == true) {
          groupData.value = jsonResponse['guruh'] ?? {};
          kidsList.value = jsonResponse['child'] ?? [];
          staffList.value = jsonResponse['guruh_user'] ?? [];
        }
      }
    } catch (e) {
      debugPrint("Group Show Error: $e");
    } finally {
      isLoading(false);
    }
  }

  String formatCurrency(dynamic amount) {
    final formatter = NumberFormat("#,###", "uz_UZ");
    return formatter.format(double.parse(amount.toString())).replaceAll(',', ' ');
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      Get.snackbar(t("Xato", "Ошибка"), t("Qo'ng'iroq qilib bo'lmadi", "Не удалось позвонить"));
    }
  }
}

// --- PAGE ---
class MyGroupShowPage extends StatefulWidget {
  final int id;
  const MyGroupShowPage({super.key, required this.id});

  @override
  State<MyGroupShowPage> createState() => _MyGroupShowPageState();
}

class _MyGroupShowPageState extends State<MyGroupShowPage> {
  late MyGroupShowController controller;

  @override
  void initState() {
    controller = Get.put(MyGroupShowController(widget.id), tag: widget.id.toString());
    super.initState();
  }

  @override
  void dispose() {
    Get.delete<MyGroupShowController>(tag: widget.id.toString());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          controller.isLoading.value
              ? controller.t("Yuklanmoqda...", "Загрузка...")
              : controller.groupData['name']?.toString() ?? "",
        )),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return _buildLoadingShimmer();

        return RefreshIndicator(
          onRefresh: () => controller.fetchGroupDetails(),
          color: const Color(0xFF6366F1),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _buildGroupDashboard()),

              // --- YANGI QO'SHILGAN TUGMALAR QATORI ---
              SliverToBoxAdapter(child: _buildActionButtons()),

              if (controller.staffList.isNotEmpty) SliverToBoxAdapter(child: _buildStaffSection()),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    controller.t("Bolalar ro'yxati", "Список детей"),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildKidCard(controller.kidsList[index]),
                    childCount: controller.kidsList.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        );
      }),
    );
  }

  // --- AMALLAR TUGMALARI (Action Buttons) ---
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 1. Davomat tarixi tugmasi
          Expanded(
            child: _actionButton(
              label: controller.t("Davomat tarixi", "История"),
              icon: Icons.history_rounded,
              color: const Color(0xFF6366F1), // Indigo
              onTap: () {
                Get.to(()=>MyGroupDavomadHistoryPage(id: widget.id));
              },
            ),
          ),
          const SizedBox(width: 12),
          // 2. Davomat olish tugmasi
          Expanded(
            child: _actionButton(
              label: controller.t("Davomat olish", "Отметить"),
              icon: Icons.fact_check_rounded,
              color: const Color(0xFF8B5CF6), // Violet/Amethyst
              onTap: () {
                Get.to(()=>MyGroupDavomadCreatePage(id: widget.id));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupDashboard() {
    final g = controller.groupData;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(g['name']?.toString() ?? "",
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const Icon(Icons.auto_awesome, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 8),
          Text(g['description']?.toString() ?? "",
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dashItem(controller.t("Bolalar", "Дети"), controller.kidsList.length.toString()),
              _dashItem(controller.t("To'lov", "Оплата"), controller.formatCurrency(g['amount'] ?? 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dashItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStaffSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(controller.t("Tarbiyachilar", "Воспитатели"),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        ),
        SizedBox(
          height: 70,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: controller.staffList.length,
            itemBuilder: (context, index) {
              final staff = controller.staffList[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: Colors.indigo.withOpacity(0.1),
                        child: const Icon(Icons.person, size: 18, color: Colors.indigo)),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(staff['full_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(staff['phone'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKidCard(dynamic kid) {
    String bDate = "---";
    try {
      if (kid['birth_date'] != null) {
        DateTime dt = DateTime.parse(kid['birth_date']);
        bDate = DateFormat('dd.MM.yyyy').format(dt);
      }
    } catch (e) { bDate = kid['birth_date'].toString().split('T')[0]; }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: kid['photo_path'] ?? "",
                width: 65, height: 65, fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[100]),
                errorWidget: (context, url, error) => Container(color: Colors.grey[100],
                    child: const Icon(Icons.person, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kid['full_name'] ?? "",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text("${controller.t("Tug'ilgan kuni", "Дата рождения")}: $bDate",
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text("${controller.t("Balans", "Баланс")}: ${controller.formatCurrency(kid['balance'])}",
                      style: TextStyle(color: (kid['balance'] < 0) ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => controller.makePhoneCall(kid['guardian_phone'] ?? ""),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_in_talk_rounded, color: Colors.green, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)))),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)))),
              ],
            ),
            const SizedBox(height: 30),
            ...List.generate(3, (index) => Container(height: 100, margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
          ],
        ),
      ),
    );
  }
}