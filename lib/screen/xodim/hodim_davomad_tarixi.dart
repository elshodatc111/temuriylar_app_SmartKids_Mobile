import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:smart_kids_app_end/const/api_const.dart';

class HodimDavomadTarixiController extends GetxController {
  final int userId;
  HodimDavomadTarixiController(this.userId);

  var isLoading = true.obs;
  var data = {}.obs;
  final box = GetStorage();

  // Tilni aniqlash
  String get lang => box.read('lang') ?? 'uz';

  @override
  void onInit() {
    fetchHistory();
    super.onInit();
  }

  // Tarjima funksiyasi
  String t(String uz, String ru) => lang == 'uz' ? uz : ru;

  Future<void> fetchHistory() async {
    try {
      isLoading(true);
      String token = box.read('token') ?? '';
      var response = await http.get(
        Uri.parse('${ApiConst.apiUrl}/user/history/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        data.value = json.decode(response.body);
      }
    } catch (e) {
      debugPrint("History Fetch Error: $e");
    } finally {
      isLoading(false);
    }
  }
}

class HodimDavomadTarixi extends StatefulWidget {
  final int id;
  const HodimDavomadTarixi({super.key, required this.id});

  @override
  State<HodimDavomadTarixi> createState() => _HodimDavomadTarixiState();
}

class _HodimDavomadTarixiState extends State<HodimDavomadTarixi> {
  late HodimDavomadTarixiController controller;

  @override
  void initState() {
    controller = Get.put(HodimDavomadTarixiController(widget.id));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          controller.isLoading.value
              ? controller.t("Yuklanmoqda...", "Загрузка...")
              : controller.data['user']['name'],
          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        )),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchHistory(),
        child: Obx(() {
          if (controller.isLoading.value) return _buildLoadingShimmer();
          if (controller.data.isEmpty) return Center(child: Text(controller.t("Ma'lumot yo'q", "Нет данных")));

          final stats = controller.data['statistics'];
          final history = controller.data['history'] as List;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Joriy oy statistikasi
                _buildSectionTitle(controller.t("Joriy oy", "Текущий месяц")),
                const SizedBox(height: 12),
                _buildStatsGrid(stats['current_month']),

                const SizedBox(height: 24),

                // O'tgan oy statistikasi
                _buildSectionTitle(controller.t("O'tgan oy", "Прошлый месяц")),
                const SizedBox(height: 12),
                _buildStatsGrid(stats['last_month']),

                const SizedBox(height: 24),

                // Kunlik tarix
                _buildSectionTitle(controller.t("Davomat tarixi", "История посещаемости")),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) => _buildHistoryItem(history[index]),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey));
  }

  Widget _buildStatsGrid(dynamic stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _statTile(controller.t("Kelgan", "Пришел"), stats['present'].toString(), Colors.green),
        _statTile(controller.t("Kechikkan", "Опоздал"), stats['late'].toString(), Colors.orange),
        _statTile(controller.t("Kelmagan", "Н/я"), stats['absent'].toString(), Colors.red),
        _statTile(controller.t("Sababli", "Причина"), stats['excused'].toString(), Colors.blue),
      ],
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHistoryItem(dynamic item) {
    Color statusColor = _getStatusColor(item['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          // Sana badge-i
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text(item['date'].toString().split('-')[2], style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(item['date'].toString().split('-')[1], style: TextStyle(color: statusColor, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 15),
          // Ma'lumotlar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _translateStatus(item['status']),
                  style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 14),
                ),
                Text(
                  "${controller.t("Belgiladi", "Отметил")}: ${item['marked_by']}",
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          // Vaqt
          Text(item['created_at'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Color _getStatusColor(String s) {
    switch (s.toLowerCase()) {
      case 'keldi': return Colors.green;
      case 'kechikdi': return Colors.orange;
      case 'kelmadi': return Colors.red;
      case 'sababli': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _translateStatus(String s) {
    switch (s.toLowerCase()) {
      case 'keldi': return controller.t("Keldi", "Пришел");
      case 'kechikdi': return controller.t("Kechikdi", "Опоздал");
      case 'kelmadi': return controller.t("Kelmadi", "Н/я");
      case 'sababli': return controller.t("Sababli", "По причине");
      default: return s;
    }
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}