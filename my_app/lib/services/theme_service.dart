
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> carregarTema() async {
    final prefs = await SharedPreferences.getInstance();

    final temaSalvo = prefs.getString("tema_aura");

    _themeMode = temaSalvo == "escuro"
        ? ThemeMode.dark
        : ThemeMode.light;

    notifyListeners();
  }

  Future<void> alterarTema(bool escuro) async {
    _themeMode = escuro ? ThemeMode.dark : ThemeMode.light;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      "tema_aura",
      escuro ? "escuro" : "claro",
    );

    notifyListeners();
  }
}