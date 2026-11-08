import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/agencias.dart';

class Preferencias extends ChangeNotifier {
  Preferencias._(this._armazenamento);

  static const _chaveHost = 'host';
  static const _chaveTemaClaro = 'temaClaro';

  final SharedPreferences _armazenamento;

  static Future<Preferencias> carregar() async => Preferencias._(await SharedPreferences.getInstance());

  String get host => _armazenamento.getString(_chaveHost) ?? hostPadrao;

  List<Agencia> get agencias => agenciasDoHost(host);

  bool get temaClaro => _armazenamento.getBool(_chaveTemaClaro) ?? false;

  Future<void> definirHost(String novoHost) async {
    await _armazenamento.setString(_chaveHost, novoHost.trim());
    notifyListeners();
  }

  Future<void> alternarTema() async {
    await _armazenamento.setBool(_chaveTemaClaro, !temaClaro);
    notifyListeners();
  }
}
