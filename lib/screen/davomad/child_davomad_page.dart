import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:smart_kids_app_end/const/api_const.dart';

class ChildAttendanceController extends GetxController {
  var isLoading = true.obs;
  var attendanceData = {}.obs;
  final box = GetStorage();

  // GetStorage dan tilni olish (default uz)
  String get lang => box.read('lang') ?? 'uz';

  // Tarjima yordamchi funksiyasi
  String t(String uz, String ru) => lang == 'uz' ? uz : ru;

  @override
  void onInit() {
    fetchAttendanceStats();
    super.onInit();
  }

  Future<void> fetchAttendanceStats() async {
    try {
      isLoading(true);
      String token = box.read('token') ?? '';
      var response = await http.get(
        Uri.parse('${ApiConst.apiUrl}/kid/attendance/chart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        attendanceData.value = json.decode(response.body);
      }
    } catch (e) {
      debugPrint("Kid Attendance Error: $e");
    } finally {
      isLoading(false);
    }
  }
}

class ChildDavomatPage extends StatelessWidget {
  const ChildDavomatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChildAttendanceController());

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.t("Bolalar davomati tahlili", "Анализ посещаемости детей")),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return _buildLoadingShimmer();
        if (controller.attendanceData.isEmpty) {
          return Center(child: Text(controller.t("Ma'lumot topilmadi", "Данные не найдены")));
        }

        final groups = controller.attendanceData['groups'] as List;
        final summary = controller.attendanceData['overall_summary'] as List;

        return RefreshIndicator(
          onRefresh: () => controller.fetchAttendanceStats(),
          color: const Color(0xFF6366F1),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Umumiy Dashboard qismi
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildMainDashboard(summary, controller),
                ),
              ),

              // Sarlavha: Guruhlar kesimida
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    controller.t("Guruhlar tahlili", "Анализ по группам"),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569)
                    ),
                  ),
                ),
              ),

              // Guruhlar ro'yxati
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildGroupAnalysisCard(groups[index], controller),
                    childCount: groups.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        );
      }),
    );
  }

  // --- ASOSIY DASHBOARD KARTASI ---
  Widget _buildMainDashboard(List summary, ChildAttendanceController controller) {
    final latest = summary.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.indigo.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  latest['month_name'],
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const Icon(Icons.insights_rounded, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLargeStat(controller.t("Faol bolalar", "Активные дети"), latest['total_active_students'].toString()),
              _buildLargeStat(controller.t("Kelganlar", "Пришли"), latest['total_keldi'].toString()),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallStat(controller.t("Kechikish", "Опоздание"), latest['total_kechikdi'].toString(), Colors.orangeAccent),
              _buildSmallStat(controller.t("Sababli", "По прич."), latest['total_sababli'].toString(), Colors.lightBlueAccent),
              _buildSmallStat(controller.t("Sababsiz", "Без прич."), latest['total_sababsiz'].toString(), Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  // --- GURUH TAHLILI KARTASI ---
  Widget _buildGroupAnalysisCard(dynamic group, ChildAttendanceController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
          ]
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.school_rounded, color: Color(0xFF4F46E5), size: 20),
        ),
        title: Text(
            group['group_name'],
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 15)
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: (group['attendance'] as List).map((att) => _buildMonthRow(att, controller)).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMonthRow(dynamic att, ChildAttendanceController controller) {
    int total = att['active_students'] == 0 ? 1 : att['active_students'];
    double progress = att['keldi'] / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  att['month_name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))
              ),
              Text(
                  "${att['keldi']} / ${att['active_students']}",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF1F5F9),
              color: progress > 0.8 ? Colors.green : (progress > 0.5 ? Colors.orange : Colors.red),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _miniDetailBadge(controller.t("Kechikish:", "Опозд:"), att['kechikdi'], Colors.orange),
              _miniDetailBadge(controller.t("Sababli:", "Причина:"), att['sababli'], Colors.blue),
              _miniDetailBadge(controller.t("Sababsiz:", "Без прич:"), att['sababsiz'], Colors.red),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
        ],
      ),
    );
  }

  // --- YORDAMCHI WIDGETLAR ---
  Widget _buildLargeStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildSmallStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _miniDetailBadge(String label, dynamic val, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)
        ),
        const SizedBox(width: 6),
        Text(
            "$label ",
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))
        ),
        Text(
            "$val",
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))
        ),
      ],
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
            Container(
                height: 180,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))
            ),
            const SizedBox(height: 20),
            ...List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                  height: 70,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))
              ),
            )),
          ],
        ),
      ),
    );
  }
}