import 'package:flutter/material.dart';
import 'package:smart_kids_app_end/screen/chart/chart_page.dart';
import 'package:smart_kids_app_end/screen/child/child_page.dart';
import 'package:smart_kids_app_end/screen/davomad/child_davomad_page.dart';
import 'package:smart_kids_app_end/screen/davomad/hodim_davomad_page.dart';
import 'package:smart_kids_app_end/screen/group/group_page.dart';
import 'package:smart_kids_app_end/screen/kassa/kassa_page.dart';
import 'package:smart_kids_app_end/screen/moliya/moliya_page.dart';
import 'package:smart_kids_app_end/screen/my_groups/my_group_page.dart';
import 'package:smart_kids_app_end/screen/my_payment/my_payment.dart';
import 'package:smart_kids_app_end/screen/tkun/tugilgan_kun_page.dart';
import 'package:smart_kids_app_end/screen/xodim/xodim_page.dart';

class MenuConst {
  static const List<Map<String, dynamic>> items = [  //
    {
      'title_uz': 'Tug\'ilgan kunlar',
      'title_ru': 'Дни рождения',
      'icon': Icons.card_giftcard_rounded,
      'color': Color(0xFFEC4899),
      'roles': ['admin', 'manager', 'tarbiyachi', 'oshpaz', 'hodim'],
      'page': TugilganKunPage(),
    },
    {
      'title_uz': 'Bolalar',
      'title_ru': 'Дети',
      'icon': Icons.child_care_rounded,
      'color': Color(0xFFFF9800),
      'roles': ['admin','manager'],
      'page': ChildPage(),
    },
    {
      'title_uz': 'Guruhlar',
      'title_ru': 'Группы',
      'icon': Icons.grid_view_rounded,
      'color': Color(0xFF2196F3), // Ko'k
      'roles': ['admin','manager'],
      'page': GroupPage(),
    },
    {
      'title_uz': 'Guruhlar davomati',
      'title_ru': 'Посещаемость групп',
      'icon': Icons.how_to_reg_rounded,
      'color': Color(0xFF00BCD4),
      'roles': ['admin','manager','tarbiyachi'],
      'page': ChildDavomatPage(),
    },
    {
      'title_uz': 'Kassa',
      'title_ru': 'Касса',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF4CAF50),
      'roles': ['admin','manager'],
      'page': KassaPage(),
    },
    {
      'title_uz': 'Xodimlar',
      'title_ru': 'Сотрудники',
      'icon': Icons.people_alt_rounded,
      'color': Color(0xFF3F51B5),
      'roles': ['admin','manager'],
      'page': XodimPage(),
    },
    {
      'title_uz': 'Xodimlar davomati',
      'title_ru': 'Посещаемость сотрудников',
      'icon': Icons.assignment_ind_rounded,
      'color': Color(0xFF673AB7), // Siyohrang
      'roles': ['admin','manager'],
      'page': HodimDavomadPage(),
    },
    {
      'title_uz': 'Moliya',
      'title_ru': 'Финансы',
      'icon': Icons.monetization_on_rounded,
      'color': Color(0xFFE91E63),
      'roles': ['admin'],
      'page': MoliyaPage(),
    },
    {
      'title_uz': 'Moliya dashboardi',
      'title_ru': 'Финансовый дашборд',
      'icon': Icons.bar_chart_rounded,
      'color': Color(0xFF607D8B),
      'roles': ['admin'],
      'page': ChartPage(),
    },
    {
      'title_uz': 'Guruhlarim',
      'title_ru': 'Мои группы',
      'icon': Icons.class_rounded,
      'color': Color(0xFF795548),
      'roles': ['tarbiyachi'],
      'page': MyGroupPage(),
    },
    {
      'title_uz': 'Ish haqi to\'lovlarim',
      'title_ru': 'Мои выплаты зарплаты',
      'icon': Icons.payments_rounded,
      'color': Color(0xFF009688),
      'roles': ['manager','tarbiyachi','oshpaz','hodim'],
      'page': MyPayment(),
    },
  ];
}