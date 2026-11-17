import 'package:flutter/widgets.dart';

/// Navigator do app, para abrir telas fora de um `BuildContext` (ex.: ao
/// tocar numa notificação).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
