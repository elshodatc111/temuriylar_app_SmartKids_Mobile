import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:smart_kids_app_end/const/api_const.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
// MANA BU IMPORTNI QO'SHING
import 'package:intl/date_symbol_data_local.dart';

class TugilganKunPage extends StatefulWidget {
  const TugilganKunPage({super.key});

  @override
  State<TugilganKunPage> createState() => _TugilganKunPageState();
}

class _TugilganKunPageState extends State<TugilganKunPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final box = GetStorage();

  List employees = [];
  List children = [];
  bool isLoading = true;
  late String lang;

  final Map<String, Map<String, String>> _words = {
    'uz': {
      'title': "Tug'ilgan kunlar",
      'staff': "Xodimlar",
      'kids': "Bolalar",
      'no_birthdays': "Yaqin 10 kunda tug'ilgan kunlar yo'q",
      'today': "Bugun tug'ilgan kun! 🎉",
      'days_left': "kun qoldi",
      'years_old': "yosh",
      'unknown': "Noma'lum",
    },
    'ru': {
      'title': "Дни рождения",
      'staff': "Сотрудники",
      'kids': "Дети",
      'no_birthdays': "В ближайшие 10 дней дней рождения нет",
      'today': "Сегодня день рождения! 🎉",
      'days_left': "дней осталось",
      'years_old': "лет",
      'unknown': "Неизвестно",
    },
  };

  @override
  void initState() {
    super.initState();
    lang = box.read('lang') ?? 'uz';
    _tabController = TabController(length: 2, vsync: this);

    // TIL PAKETINI INIZIALIZATSIYA QILISH
    initializeDateFormatting(lang, null).then((_) {
      if (mounted) {
        _fetchData();
      }
    });
  }

  String t(String key) => _words[lang]![key] ?? key;

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    String? token = box.read('token');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final empResponse = await http.get(
        Uri.parse('${ApiConst.apiUrl}/emploes/tkun'),
        headers: headers,
      );

      final childResponse = await http.get(
        Uri.parse('${ApiConst.apiUrl}/emploes/tkun/child'),
        headers: headers,
      );

      if (empResponse.statusCode == 200 && childResponse.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          employees = json.decode(empResponse.body)['users'] ?? [];
          children = json.decode(childResponse.body)['users'] ?? [];
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint("Xatolik: $e");
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: "+$phoneNumber");
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  int _calculateAge(String birthDate) {
    try {
      DateTime birth = DateTime.parse(birthDate);
      DateTime now = DateTime.now();
      int age = now.year - birth.year;
      return age;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          t('title'),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Color(0xFF0F172A),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.indigoAccent,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: Colors.indigoAccent,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(child: Text(t('staff'), style: const TextStyle(fontWeight: FontWeight.bold))),
            Tab(child: Text(t('kids'), style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
        child: SpinKitThreeBounce(color: Colors.indigoAccent, size: 35.0),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildList(employees, "employee"),
          _buildList(children, "child"),
        ],
      ),
    );
  }

  Widget _buildList(List data, String type) {
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            t('no_birthdays'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          return _buildCard(item, type);
        },
      ),
    );
  }

  Widget _buildCard(Map item, String type) {
    bool isEmployee = type == "employee";
    String name = (isEmployee ? item['name'] : item['full_name']) ?? t('unknown');
    String image = (isEmployee ? item['image'] : item['photo_path']) ?? "";
    String birthDate = item['birth'] ?? DateTime.now().toString();
    int daysLeft = item['days_until_birthday'] ?? 0;
    String phone = isEmployee ? (item['phone'] ?? "") : (item['guardian_phone'] ?? "");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CachedNetworkImage(
                    imageUrl: image,
                    width: 65,
                    height: 65,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade100),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.indigo.withOpacity(0.1),
                      child: const Icon(Icons.person, color: Colors.indigo),
                    ),
                  ),
                ),
                if (daysLeft == 0)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
                    child: const Icon(Icons.cake_rounded, color: Colors.white, size: 14),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${DateFormat('dd-MMMM', lang).format(DateTime.parse(birthDate))} • ${_calculateAge(birthDate)} ${t('years_old')}",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: daysLeft == 0 ? Colors.green.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      daysLeft == 0 ? t('today') : "$daysLeft ${t('days_left')}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: daysLeft == 0 ? Colors.green : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isEmployee && phone.isNotEmpty)
              Material(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => _makeCall(phone),
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(Icons.phone_forwarded_rounded, color: Colors.green, size: 22),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}