import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/agencias.dart';
import '../dados/api_cliente.dart';
import 'preferencias.dart';

class Sessao {
  const Sessao({required this.token, required this.contaId});

  final String token;
  final int contaId;
}

/// Guarda o JWT no armazenamento seguro do Android, para reenviar nas proximas
/// requisicoes e manter a sessao entre aberturas do app.
class SessaoEstado extends ChangeNotifier {
  SessaoEstado(this._preferencias);

  static const _chaveToken = 'token';
  static const _chaveConta = 'contaId';

  final Preferencias _preferencias;
  final _cofre = const FlutterSecureStorage();

  Sessao? sessao;
  String? avisoLogin;

  Agencia get agencia => _preferencias.agencias[agenciaDaConta(sessao!.contaId)];

  Future<void> restaurar() async {
    final token = await _cofre.read(key: _chaveToken);
    final conta = await _cofre.read(key: _chaveConta);
    if (token != null && conta != null) {
      sessao = Sessao(token: token, contaId: int.parse(conta));
    }
  }

  Future<void> entrar(int contaId, String senha) async {
    final agencia = _preferencias.agencias[agenciaDaConta(contaId)];
    final resultado = await chamarApi(
      agencia.url,
      '/auth/login',
      metodo: 'POST',
      corpo: {'id': contaId, 'senha': senha},
    );
    final token = resultado['accessToken'] as String;
    await _cofre.write(key: _chaveToken, value: token);
    await _cofre.write(key: _chaveConta, value: '$contaId');
    sessao = Sessao(token: token, contaId: contaId);
    avisoLogin = null;
    notifyListeners();
  }

  Future<void> encerrar({String? aviso}) async {
    await _cofre.delete(key: _chaveToken);
    await _cofre.delete(key: _chaveConta);
    sessao = null;
    avisoLogin = aviso;
    notifyListeners();
  }
}
