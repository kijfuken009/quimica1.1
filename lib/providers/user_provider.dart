import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;

  // Getter para acceder al usuario desde cualquier pantalla
  UserModel? get user => _user;

  // Carga los datos guardados en el teléfono al iniciar la app
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('user_data');

    if (userData != null) {
      _user = UserModel.fromJson(jsonDecode(userData));
      notifyListeners();
    }
  }

  // Guarda el usuario por primera vez (en la pantalla de Onboarding)
  Future<void> saveUser(String name, int age) async {
    _user = UserModel(
      name: name,
      age: age,
      chemistryLevel: 1,
      totalPoints: 0,
      unlockedLevel: 1,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  // Suma puntos y desbloquea el siguiente nivel
  Future<void> addPointsAndUnlockLevel({
    required int pointsWon,
    required int completedLevel,
    required bool passed,
  }) async {
    if (_user == null) return;

    int newUnlockedLevel = _user!.unlockedLevel;
    if (passed && _user!.unlockedLevel == completedLevel) {
      newUnlockedLevel = completedLevel + 1;
    }

    _user = _user!.copyWith(
      totalPoints: _user!.totalPoints + pointsWon,
      unlockedLevel: newUnlockedLevel,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  // Permite cambiar el apodo desde la pantalla de configuración
  Future<void> updateNickname(String newName) async {
    if (_user != null) {
      _user = _user!.copyWith(name: newName);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));
      notifyListeners();
    }
  }

  // Método para borrar usuario (Resetear la app)
  Future<void> clearUser() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    notifyListeners();
  }
}