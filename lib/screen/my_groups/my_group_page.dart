import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:smart_kids_app_end/const/api_const.dart';
import 'package:smart_kids_app_end/screen/my_groups/my_group_show_page.dart';

class MyGroupController extends GetxController {
  var isLoading = true.obs;
  var groups = <dynamic>[].obs;
  final box = GetStorage();

  // Tilni aniqlash
  String get lang => box.read('lang') ?? 'uz';

  // Tarjima yordamchi funksiyasi
  String t(String uz, String ru) => lang == 'uz' ? uz : ru;

  @override
  void onInit() {
    fetchMyGroups();
    super.onInit();
  }

  Future<void> fetchMyGroups() async {
    try {
      isLoading(true);
      String token = box.read('token') ?? '';
      var response = await http.get(
        Uri.parse('${ApiConst.apiUrl}/kid/tarbiyachi/groups'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['status']) {
          groups.value = jsonResponse['data'];
        }
      }
    } catch (e) {
      debugPrint("Groups Fetch Error: $e");
    } finally {
      isLoading(false);
    }
  }
}

class MyGroupPage extends StatelessWidget {
  const MyGroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyGroupController());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.t("Mening guruhlarim", "Мои группы"),
        ),
        actions: [
          IconButton(
            onPressed: () => controller.fetchMyGroups(),
            icon: const Icon(Icons.refresh_rounded, color: Colors.blue),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) return _buildLoadingShimmer();

        if (controller.groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_off_outlined,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  controller.t(
                    "Guruhlar biriktirilmagan",
                    "Группы не прикреплены",
                  ),
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchMyGroups(),
          color: Colors.indigo,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: controller.groups.length,
            itemBuilder: (context, index) {
              final group = controller.groups[index];
              return _buildGroupCard(group, controller);
            },
          ),
        );
      }),
    );
  }

  Widget _buildGroupCard(dynamic group, MyGroupController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            print("Group ID: ${group['id']}");
            Get.to(()=>MyGroupShowPage(id: group['id']));
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Guruh Ikonkasi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Color(0xFF4F46E5),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),

                // Guruh Nomi va Ma'lumoti
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.t("Batafsil ko'rish", "Просмотреть детали"),
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // O'tish tugmasi
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
