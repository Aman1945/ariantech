import 'package:flutter/material.dart';

class TabControllerNew{
  int _currentTab = 0;
  final List<VoidCallback> _listeners = [];

  int get currentTab => _currentTab;

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void changeTab(int index) {
    if (_currentTab != index) {
      _currentTab = index;
      for (final listener in _listeners) {
        listener();
      }
    }
  }

  void dispose() {
    _listeners.clear();
  }
}
