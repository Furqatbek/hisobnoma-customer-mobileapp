import 'package:flutter/foundation.dart';

/// A single entry on a tab's navigation stack.
class ScreenSpec {
  final String name;
  final int? productId;
  final String? orderNumber;
  final double? total;
  final String? payMethod;
  final bool? paid;
  const ScreenSpec(this.name,
      {this.productId, this.orderNumber, this.total, this.payMethod, this.paid});
}

enum NavMotion { push, pop, none }

/// Per-tab navigation stacks and the slide-direction hint the shell animates
/// with. Pure UI navigation — no repositories, no persistence.
class NavController extends ChangeNotifier {
  String tab = 'catalog';
  NavMotion motion = NavMotion.none;
  final Map<String, List<ScreenSpec>> stacks = {
    'catalog': [const ScreenSpec('catalog')],
    'cart': [const ScreenSpec('cart')],
    'wallet': [const ScreenSpec('wallet')],
    'wishlist': [const ScreenSpec('wishlist')],
    'profile': [const ScreenSpec('profile')],
  };

  List<ScreenSpec> get stack => stacks[tab]!;
  ScreenSpec get screen => stack.last;
  bool get showTabBar => stack.length == 1;

  void setTab(String t) {
    motion = NavMotion.none;
    tab = t;
    notifyListeners();
  }

  void push(ScreenSpec s) {
    motion = NavMotion.push;
    stack.add(s);
    notifyListeners();
  }

  void pop() {
    motion = NavMotion.pop;
    if (stack.length > 1) stack.removeLast();
    notifyListeners();
  }

  void replace(ScreenSpec s) {
    motion = NavMotion.push;
    stacks[tab] = [ScreenSpec(stack.first.name), s];
    notifyListeners();
  }

  void resetCartStack() {
    motion = NavMotion.none;
    stacks['cart'] = [const ScreenSpec('cart')];
    notifyListeners();
  }

  /// Clear the slide hint (e.g. on logout) without animating.
  void resetMotion() => motion = NavMotion.none;
}
