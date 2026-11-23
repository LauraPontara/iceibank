import 'dart:math';

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
  static const _maxTentativasNumero = 8;
  static final _sorteio = Random();

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

  /// Cria a conta na agencia responsavel pelo numero (id % 3) e ja entra nela.
  /// Sem numero informado, sorteia um livre, tentando de novo quando ja existe.
  /// A conta precisa da agencia no ar: so ela confirma se o numero esta livre,
  /// entao a abertura nao entra no modo offline-first.
  Future<int> abrirConta({required String nome, required String senha, int? numero}) async {
    final int id;
    if (numero == null) {
      id = await _sortearNumeroLivre(nome, senha);
    } else {
      await _criarConta(numero, nome, senha);
      id = numero;
    }

    try {
      await entrar(id, senha);
    } on ErroApi {
      _avisarContaCriadaSemLogin(id);
    } on SemConexao {
      _avisarContaCriadaSemLogin(id);
    }
    return id;
  }

  Future<int> _sortearNumeroLivre(String nome, String senha) async {
    for (var tentativa = 0; tentativa < _maxTentativasNumero; tentativa++) {
      final id = 1000 + _sorteio.nextInt(9000);
      try {
        await _criarConta(id, nome, senha);
        return id;
      } on ErroApi catch (e) {
        if (e.status != 409) rethrow;
      }
    }
    throw ErroApi(409, 'Não foi possível gerar um número de conta livre. Tente novamente.');
  }

  Future<void> _criarConta(int id, String nome, String senha) async {
    final agencia = _preferencias.agencias[agenciaDaConta(id)];
    await chamarApi(
      agencia.url,
      '/contas',
      metodo: 'POST',
      corpo: {'id': id, 'nomeAluno': nome.trim(), 'senha': senha},
    );
  }

  void _avisarContaCriadaSemLogin(int id) {
    avisoLogin = 'Conta $id criada, mas o login automático falhou. Entre com o número e a senha.';
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
