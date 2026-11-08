import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../dados/api_cliente.dart';
import 'sessao_estado.dart';

const intervaloAtualizacaoSaldo = Duration(seconds: 5);

class Conta {
  const Conta({required this.id, required this.nomeAluno, required this.saldo});

  final int id;
  final String nomeAluno;
  final double saldo;

  factory Conta.deJson(Map<String, dynamic> json) => Conta(
        id: json['id'] as int,
        nomeAluno: json['nomeAluno'] as String,
        saldo: (json['saldo'] as num).toDouble(),
      );
}

class ContaEstado extends ChangeNotifier {
  ContaEstado(this._sessao);

  final SessaoEstado _sessao;
  Timer? _temporizador;

  Conta? conta;
  String? erro;

  void iniciar() {
    atualizar();
    _temporizador ??= Timer.periodic(intervaloAtualizacaoSaldo, (_) => atualizar());
  }

  void parar() {
    _temporizador?.cancel();
    _temporizador = null;
  }

  void limpar() {
    parar();
    conta = null;
    erro = null;
  }

  Future<Map<String, dynamic>> _chamar(String caminho, {String metodo = 'GET', Map<String, dynamic>? corpo}) async {
    final sessao = _sessao.sessao;
    if (sessao == null) throw SemConexao('Sessão encerrada.');
    try {
      return await chamarApi(_sessao.agencia.url, caminho, metodo: metodo, corpo: corpo, token: sessao.token);
    } on ErroApi catch (e) {
      if (e.status == 401) await _sessao.encerrar(aviso: 'Sessão expirada. Faça login novamente.');
      rethrow;
    }
  }

  Future<void> atualizar() async {
    final sessao = _sessao.sessao;
    if (sessao == null) return;
    try {
      conta = Conta.deJson(await _chamar('/contas/${sessao.contaId}'));
      erro = null;
    } on SemConexao catch (e) {
      erro = e.mensagem;
    } on ErroApi catch (e) {
      erro = e.mensagem;
    }
    notifyListeners();
  }

  Future<void> depositar(double valor) async {
    await _chamar('/contas/${_sessao.sessao!.contaId}/depositar', metodo: 'POST', corpo: {'valor': valor});
    await atualizar();
  }

  Future<void> sacar(double valor) async {
    await _chamar('/contas/${_sessao.sessao!.contaId}/sacar', metodo: 'POST', corpo: {'valor': valor});
    await atualizar();
  }

  Future<String> transferir(int idDestino, double valor) async {
    final resultado = await _chamar('/transferencias', metodo: 'POST', corpo: {
      'idOrigem': _sessao.sessao!.contaId,
      'idDestino': idDestino,
      'valor': valor,
      'idempotencyKey': const Uuid().v4(),
    });
    await atualizar();
    return resultado['mensagem'] as String;
  }
}
