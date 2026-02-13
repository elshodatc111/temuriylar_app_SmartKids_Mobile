import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smart_kids_app_end/const/api_const.dart';

class ChildUpdatePage extends StatefulWidget {
  final int id;
  const ChildUpdatePage({super.key, required this.id});

  @override
  State<ChildUpdatePage> createState() => _ChildUpdatePageState();
}

class _ChildUpdatePageState extends State<ChildUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  final box = GetStorage();
  bool isLoading = true;
  bool isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _guardianNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  var maskFormatter = MaskTextInputFormatter(
    mask: '## ### ## ##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  late String lang;

  @override
  void initState() {
    super.initState();
    lang = box.read('lang') ?? 'uz';
    _fetchChildData();
  }

  // Yuqori qismdan chiquvchi zamonaviy SnackBar
  void _showTopSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 160,
          left: 20,
          right: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  Future<void> _fetchChildData() async {
    setState(() => isLoading = true);
    String? token = box.read('token');

    try {
      final response = await http.get(
        Uri.parse('${ApiConst.apiUrl}/kids/show/${widget.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['kid'];
        setState(() {
          _nameController.text = data['full_name'] ?? '';
          _guardianNameController.text = data['guardian_name'] ?? '';
          _addressController.text = data['address'] ?? '';
          _bioController.text = data['biography'] ?? '';

          String rawPhone = data['guardian_phone'] ?? '';
          String digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.startsWith('998')) {
            digits = digits.substring(3);
          }
          _phoneController.value = maskFormatter.formatEditUpdate(
            const TextEditingValue(text: ''),
            TextEditingValue(text: digits),
          );

          if (data['birth_date'] != null) {
            DateTime dt = DateTime.parse(data['birth_date']);
            _birthDateController.text = DateFormat('yyyy-MM-dd').format(dt);
          }
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showTopSnackBar(lang == 'uz' ? "Ma'lumotlarni yuklashda xatolik" : "Ошибка загрузки данных", Colors.redAccent, Icons.error_outline);
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isSaving = true);

      String? token = box.read('token');
      String cleanPhone = maskFormatter.getUnmaskedText();
      String finalPhone = "+998$cleanPhone";

      final updatedData = {
        "full_name": _nameController.text,
        "birth_date": "${_birthDateController.text}T00:00:00.000000Z",
        "guardian_name": _guardianNameController.text,
        "guardian_phone": finalPhone,
        "address": _addressController.text,
        "biography": _bioController.text,
      };

      try {
        final response = await http.post(
          Uri.parse('${ApiConst.apiUrl}/kids/update/${widget.id}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(updatedData),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (!mounted) return;
          _showTopSnackBar(lang == 'uz' ? "Muvaffaqiyatli saqlandi" : "Успешно сохранено", Colors.green, Icons.check_circle_outline);
          Navigator.pop(context, true);
        } else {
          throw Exception();
        }
      } catch (e) {
        if (!mounted) return;
        _showTopSnackBar(lang == 'uz' ? "Xatolik yuz berdi" : "Произошла ошибка", Colors.redAccent, Icons.error_outline);
      } finally {
        if (mounted) setState(() => isSaving = false);
      }
    } else {
      _showTopSnackBar(lang == 'uz' ? "Barcha maydonlarni to'ldiring" : "Заполните все поля", Colors.orangeAccent, Icons.warning_amber_rounded);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2019),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.indigoAccent)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang == 'uz' ? "Tahrirlash" : "Редактирование",
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 18),
        ),
      ),
      body: isLoading
          ? const Center(child: SpinKitThreeBounce(color: Colors.indigoAccent, size: 30.0))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(lang == 'uz' ? "Shaxsiy ma'lumotlar" : "Личные данные"),
              _buildTextField(
                controller: _nameController,
                label: lang == 'uz' ? "Bolaning F.I.SH" : "Ф.И.О ребенка",
                icon: Icons.badge_outlined,
                validator: (v) => v!.isEmpty ? (lang == 'uz' ? "Ismni kiriting" : "Введите имя") : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _birthDateController,
                label: lang == 'uz' ? "Tug'ilgan sanasi" : "Дата рождения",
                icon: Icons.calendar_month_outlined,
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (v) => v!.isEmpty ? (lang == 'uz' ? "Sanani tanlang" : "Выберите дату") : null,
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(lang == 'uz' ? "Vasiy ma'lumotlari" : "Данные опекуна"),
              _buildTextField(
                controller: _guardianNameController,
                label: lang == 'uz' ? "Vasiyning F.I.SH" : "Ф.И.О опекуна",
                icon: Icons.family_restroom_outlined,
                validator: (v) => v!.isEmpty ? (lang == 'uz' ? "Vasiy ismini kiriting" : "Введите имя опекуна") : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _phoneController,
                label: lang == 'uz' ? "Telefon raqami" : "Номер телефона",
                icon: Icons.phone_iphone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [maskFormatter],
                isPhone: true,
                validator: (v) => v!.replaceAll(' ', '').length < 9
                    ? (lang == 'uz' ? "Raqamni to'liq kiriting" : "Введите номер полностью") : null,
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(lang == 'uz' ? "Qo'shimcha" : "Дополнительно"),
              _buildTextField(
                controller: _addressController,
                label: lang == 'uz' ? "Yashash manzili" : "Адрес проживания",
                icon: Icons.map_outlined,
                validator: (v) => v!.isEmpty ? (lang == 'uz' ? "Manzilni kiriting" : "Введите адрес") : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _bioController,
                label: lang == 'uz' ? "Qisqacha ma'lumot" : "Краткая информация",
                icon: Icons.notes_outlined,
                maxLines: 3,
                validator: (v) => v!.isEmpty ? (lang == 'uz' ? "Ma'lumot kiriting" : "Введите информацию") : null,
              ),
              const SizedBox(height: 40),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade600, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool isPhone = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      cursorColor: Colors.indigoAccent,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.indigoAccent, size: 20),
        prefix: isPhone ? const Padding(
          padding: EdgeInsets.only(right: 8),
          child: Text("+998 ", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
        ) : null,
        floatingLabelStyle: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.indigoAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isSaving)
            BoxShadow(
              color: Colors.indigoAccent.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isSaving ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigoAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.indigoAccent.withOpacity(0.6),
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: isSaving
            ? const SpinKitRing(color: Colors.white, size: 24, lineWidth: 3)
            : Text(
          lang == 'uz' ? "SAQLASH" : "СОХРАНИТЬ",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _guardianNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}