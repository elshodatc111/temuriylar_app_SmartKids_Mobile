import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:smart_kids_app_end/const/api_const.dart';

class FinanceController extends GetxController {
  var isLoading = true.obs;
  var yearlyStats = <dynamic>[].obs;
  final box = GetStorage();

  // GetStorage dan tilni olish (default uz)
  String get lang => box.read('lang') ?? 'uz';

  // Tarjima yordamchi funksiyasi
  String t(String uz, String ru) => lang == 'uz' ? uz : ru;

  @override
  void onInit() {
    fetchFinanceStats();
    super.onInit();
  }

  Future<void> fetchFinanceStats() async {
    try {
      isLoading(true);
      String token = box.read('token') ?? '';
      var response = await http.get(
        Uri.parse('${ApiConst.apiUrl}/finance/charts/monch'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['success']) {
          yearlyStats.value = jsonResponse['yearly_stats'];
        }
      }
    } catch (e) {
      debugPrint("Finance API Error: $e");
    } finally {
      isLoading(false);
    }
  }

  String formatMoney(dynamic amount) {
    final formatter = NumberFormat("#,###", "uz_UZ");
    return formatter.format(double.parse(amount.toString())).replaceAll(',', ' ');
  }
}

class ChartPage extends StatelessWidget {
  const ChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FinanceController());

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.t("Moliya dashboardi", "Финансовый дашборд"),),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return _buildLoadingShimmer();
        if (controller.yearlyStats.isEmpty) {
          return Center(child: Text(controller.t("Ma'lumot topilmadi", "Данные не найдены")));
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchFinanceStats(),
          color: Colors.blue,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Oxirgi 3 oylik batafsil diagramma
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegend(controller),
                      const SizedBox(height: 12),
                      _buildThreeMonthDetailedChart(controller.yearlyStats.take(3).toList(), controller),
                    ],
                  ),
                ),
              ),

              // 2. Yillik hisobotlar sarlavhasi
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    controller.t("Yillik hisobotlar", "Годовые отчеты"),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                ),
              ),

              // 3. 12 oylik to'liq tarix
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildMonthlyFinanceCard(controller.yearlyStats[index], controller),
                    childCount: controller.yearlyStats.length,
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

  // --- 3 OYLIK DETALIZATSIYA DIAGRAMMASI ---
  Widget _buildThreeMonthDetailedChart(List stats, FinanceController controller) {
    var chartData = stats.reversed.toList();

    return Container(
      height: 300,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _calculateMaxY(chartData),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  controller.formatMoney(rod.toY),
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= chartData.length) return const SizedBox();
                  // Oy nomini qisqartirish (Feb, Yan...)
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                        chartData[index]['month_name'].toString().split(' ')[0].substring(0, 3),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(chartData.length, (i) {
            var s = chartData[i]['stats'];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(toY: _parse(s['kirim']), color: Colors.blue, width: 6),
                BarChartRodData(toY: _parse(s['ish_haqi']), color: Colors.orange, width: 6),
                BarChartRodData(toY: _parse(s['xarajat']), color: Colors.redAccent, width: 6),
                BarChartRodData(toY: _parse(s['shaxsiy_daromad']), color: Colors.purple, width: 6),
                BarChartRodData(toY: _parse(s['exson']), color: Colors.teal, width: 6),
              ],
            );
          }),
        ),
      ),
    );
  }

  double _parse(dynamic val) => double.tryParse(val.toString()) ?? 0;

  double _calculateMaxY(List stats) {
    double max = 0;
    for (var item in stats) {
      double kirim = _parse(item['stats']['kirim']);
      if (kirim > max) max = kirim;
    }
    return max == 0 ? 1000 : max * 1.2;
  }

  // --- LEGEND (Grafik tushuntirmasi) ---
  Widget _buildLegend(FinanceController controller) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _legendItem(controller.t("Kirim", "Приход"), Colors.blue),
        _legendItem(controller.t("Maosh", "Зарплата"), Colors.orange),
        _legendItem(controller.t("Xarajat", "Расход"), Colors.redAccent),
        _legendItem(controller.t("Daromad", "Доход"), Colors.purple),
        _legendItem(controller.t("Ehson", "Благотворит."), Colors.teal),
      ],
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- OYLIK HISOBOT KARTASI ---
  Widget _buildMonthlyFinanceCard(dynamic data, FinanceController controller) {
    var s = data['stats'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.receipt_long_rounded, color: Colors.indigo),
        title: Text(data['month_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
            "${controller.t("Sof foyda", "Чистая прибыль")}: ${controller.formatMoney(s['qoldiq'])}",
            style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row(controller.t("Umumiy kirim", "Общий приход"), s['kirim'], Colors.blue, controller),
                _row(controller.t("Xodimlar maoshi", "Зарплата сотрудников"), s['ish_haqi'], Colors.orange, controller),
                _row(controller.t("Boshqa xarajatlar", "Прочие расходы"), s['xarajat'], Colors.redAccent, controller),
                _row(controller.t("Shaxsiy daromad", "Личный доход"), s['shaxsiy_daromad'], Colors.purple, controller),
                _row(controller.t("Ehson (Xayriya)", "Благотворительность"), s['exson'], Colors.teal, controller),
                const Divider(),
                _row(controller.t("Kassa qoldig'i", "Остаток в кассе"), s['qoldiq'], Colors.green, controller, isBold: true),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _row(String label, dynamic val, Color color, FinanceController controller, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  color: isBold ? Colors.black : Colors.grey[600],
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal
              )
          ),
          Text(
              "${controller.formatMoney(val)} ${controller.t("UZS", "UZS")}",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)
          ),
        ],
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
            Container(height: 300, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
            const SizedBox(height: 20),
            ...List.generate(3, (i) => Container(height: 80, margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
          ],
        ),
      ),
    );
  }
}