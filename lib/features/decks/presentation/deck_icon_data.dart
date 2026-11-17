import 'package:flutter/material.dart';

import '../models/deck_icon.dart';

/// Ícone do Material para cada [DeckIcon].
extension DeckIconData on DeckIcon {
  IconData get data => switch (this) {
        DeckIcon.general => Icons.menu_book_outlined,
        DeckIcon.health => Icons.monitor_heart_outlined,
        DeckIcon.food => Icons.restaurant_outlined,
        DeckIcon.home => Icons.home_outlined,
        DeckIcon.travel => Icons.flight_outlined,
        DeckIcon.work => Icons.work_outline,
        DeckIcon.school => Icons.school_outlined,
        DeckIcon.clothes => Icons.checkroom_outlined,
        DeckIcon.family => Icons.people_outline,
        DeckIcon.nature => Icons.park_outlined,
        DeckIcon.time => Icons.schedule_outlined,
        DeckIcon.shopping => Icons.shopping_bag_outlined,
      };

  /// Nome do tema, para leitores de tela.
  String get label => switch (this) {
        DeckIcon.general => 'Geral',
        DeckIcon.health => 'Saúde',
        DeckIcon.food => 'Comida',
        DeckIcon.home => 'Casa',
        DeckIcon.travel => 'Viagem',
        DeckIcon.work => 'Trabalho',
        DeckIcon.school => 'Estudos',
        DeckIcon.clothes => 'Roupas',
        DeckIcon.family => 'Pessoas',
        DeckIcon.nature => 'Natureza',
        DeckIcon.time => 'Tempo',
        DeckIcon.shopping => 'Compras',
      };
}
