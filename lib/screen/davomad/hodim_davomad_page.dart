import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:smart_kids_app_end/const/api_const.dart';

class AttendanceController extends GetxController {
  var isLoading = true.obs;
  var isSaving = false.obs;
  var statsData = {}.obs;
  var staffList = <dynamic>[].obs;
  final box = GetStorage();

  String get lang => box.read('lang') ?? 'uz';

  @override
  void onInit() {
    fetchStats();
    super.onInit();
  }

  String t(String uz, String ru) => lang == 'uz' ? uz : ru;

  Future<void> fetchStats() async {
    try {
      isLoading(true);
      String token = box.read('token') ?? '';
      var response = await http.get(
        Uri.parse('${ApiConst.apiUrl}/user/attendance/general-stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        statsData.value = json.decode(response.body);
      }
    } catch (e) {
      debugPrint("Stats Error: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchStaffForAttendance() async {
    try {
      staffList.clear();
      String token = box.read('token') ?? '';
      var response = await http.get(
        Uri.parse(
          '${ApiConst.apiUrl}/user/get/davomad',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        staffList.value = json.decode(response.body);
      }
    } catch (e) {
      debugPrint("Staff Fetch Error: $e");
    }
  }

  Future<void> submitAttendance() async {
    try {
      isSaving(true);
      String token = box.read('token') ?? '';
      List attendanceData = staffList
          .map((e) => {"user_id": e['user_id'], "status": e['status']})
          .toList();

      var response = await http.post(
        Uri.parse(
          '${ApiConst.apiUrl}/user/davomat',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({"attendances": attendanceData}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        await fetchStats();
        Get.snackbar(
          t("Muvaffaqiyatli", "Успешно"),
          t("Davomat saqlandi", "Посещаемость сохранена"),
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("Submit Error: $e");
    } finally {
      isSaving(false);
    }
  }
}

class HodimDavomadPage extends StatelessWidget {
  const HodimDavomadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AttendanceController());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(controller.t("Xodimlar davomat tahlili", "Анализ посещаемости")),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.add_task_rounded,
                color: Colors.blue,
                size: 26,
              ),
              onPressed: () {
                controller.fetchStaffForAttendance();
                _showAttendanceModal(context, controller);
              },
            ),
            const SizedBox(width: 10),
          ],
          bottom: TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(text: controller.t("Joriy oy", "Текущий месяц")),
              Tab(text: controller.t("O'tgan oy", "Прошлый месяц")),
              Tab(text: controller.t("Yillik", "Годовой")),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) return _buildLoadingShimmer();
          if (controller.statsData.isEmpty)
            return Center(
              child: Text(
                controller.t("Ma'lumot topilmadi", "Данные не найдены"),
              ),
            );

          return RefreshIndicator(
            onRefresh: () => controller.fetchStats(),
            color: Colors.blue,
            child: TabBarView(
              children: [
                _buildMonthTab(
                  controller.statsData['current_month_issues'],
                  controller,
                ),
                _buildMonthTab(
                  controller.statsData['last_month_issues'],
                  controller,
                ),
                _buildYearlyTab(
                  controller.statsData['yearly_history'],
                  controller,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMonthTab(dynamic data, AttendanceController controller) {
    if (data == null)
      return Center(child: Text(controller.t("Ma'lumot yo'q", "Нет данных")));
    final List issues = data['issues'] ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatGrid(data, controller),
          const SizedBox(height: 25),
          Text(
            controller.t("Intizom hisoboti", "Отчет по дисциплине"),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (issues.isEmpty)
            _buildEmptyState(controller)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: issues.length,
              itemBuilder: (context, index) =>
                  _buildIssueCard(issues[index], controller),
            ),
          const SizedBox(height: 20),
          _buildEfficiencyCard(data['attendance_rate'], controller),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatGrid(dynamic data, AttendanceController controller) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _statItem(
          controller.t("Jami", "Всего"),
          data['total_employees'].toString(),
          Icons.people,
          Colors.blue,
        ),
        _statItem(
          controller.t("Kelgan", "Пришли"),
          data['present'].toString(),
          Icons.check_circle_outline,
          Colors.green,
        ),
        _statItem(
          controller.t("Kechikkan", "Опоздали"),
          data['late'].toString(),
          Icons.access_time,
          Colors.orange,
        ),
        _statItem(
          controller.t("Kelmagan", "Отсутствуют"),
          data['absent'].toString(),
          Icons.highlight_off,
          Colors.red,
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(dynamic issue, AttendanceController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange.withOpacity(0.1),
            child: const Icon(Icons.person, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (issue['late_count'] > 0)
                      _badge(
                        controller.t(
                          "Kechikkan: ${issue['late_count']}",
                          "Опоздал: ${issue['late_count']}",
                        ),
                        Colors.orange,
                      ),
                    if (issue['absent_count'] > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _badge(
                          controller.t(
                            "Kelmagan: ${issue['absent_count']}",
                            "Н/я: ${issue['absent_count']}",
                          ),
                          Colors.red,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAttendanceModal(
    BuildContext context,
    AttendanceController controller,
  ) {
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        height: Get.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                controller.t("Kunlik davomat", "Ежедневная посещаемость"),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Obx(
                () => controller.staffList.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: controller.staffList.length,
                        itemBuilder: (context, index) {
                          final staff = controller.staffList[index];
                          return _buildStaffRow(staff, index, controller);
                        },
                      ),
              ),
            ),
            _buildSaveButton(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffRow(
    dynamic staff,
    int index,
    AttendanceController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            staff['name'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statusItem(
                  'keldi',
                  controller.t("Keldi", "Пришел"),
                  Colors.green,
                  staff,
                  index,
                  controller,
                ),
                _statusItem(
                  'kechikdi',
                  controller.t("Kechikdi", "Опоздал"),
                  Colors.orange,
                  staff,
                  index,
                  controller,
                ),
                _statusItem(
                  'kelmadi',
                  controller.t("Kelmadi", "Н/я"),
                  Colors.red,
                  staff,
                  index,
                  controller,
                ),
                _statusItem(
                  'sababli',
                  controller.t("Sababli", "Причина"),
                  Colors.blue,
                  staff,
                  index,
                  controller,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusItem(
    String st,
    String label,
    Color color,
    dynamic staff,
    int index,
    AttendanceController controller,
  ) {
    bool isSel = staff['status'] == st;
    return InkWell(
      onTap: () {
        staff['status'] = st;
        controller.staffList.refresh();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSel ? color : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isSel ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(AttendanceController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(
        () => ElevatedButton(
          onPressed: controller.isSaving.value
              ? null
              : () => controller.submitAttendance(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: controller.isSaving.value
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  controller.t("Saqlash", "Сохранить"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEfficiencyCard(dynamic rate, AttendanceController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            controller.t("Samaradorlik", "Эффективность"),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            "$rate%",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AttendanceController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(
          controller.t(
            "Hamma xodimlar intizomli ✅",
            "Все сотрудники дисциплинированы ✅",
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.green, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildYearlyTab(List data, AttendanceController controller) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              "${item['month']} ${item['year']}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              controller.t(
                "Keldi: ${item['present']} | Kechikdi: ${item['late']} | Kelmmadi: ${item['absent']}",
                "Пришел: ${item['present']} | Уже поздно.: ${item['late']} | Не пришёл: ${item['absent']}",
              ),
            ),
            trailing: Text(
              "${item['attendance_rate']}%",
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white,
        ),
      ),
    );
  }
}
