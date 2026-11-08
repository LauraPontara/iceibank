import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/agencias.dart';
import '../dados/api_cliente.dart';
import 'preferencias.dart';

/// O heartbeat das agencias roda a cada 3s, entao consultar no mesmo ritmo mostra
/// uma troca de lider logo depois dela acontecer sem gastar bateria a toa.
const intervaloConsultaLider = Duration(seconds: 3);
const tempoLimiteConsultaLider = Duration(milliseconds: 1500);

enum StatusLideranca { consultando, definida, emEleicao, semResposta }

class LiderancaEstado extends ChangeNotifier {
  LiderancaEstado(this._preferencias);

  final Preferencias _preferencias;
  Timer? _temporizador;
  bool _consultaEmAndamento = false;

  StatusLideranca status = StatusLideranca.consultando;
  int? lider;
  int? liderAnterior;
  DateTime? trocaEm;
  int concordam = 0;

  /// Ids das agencias que responderam na ultima consulta.
  Set<int> ativas = const {};

  void iniciar() {
    _consultar();
    _temporizador ??= Timer.periodic(intervaloConsultaLider, (_) => _consultar());
  }

  void parar() {
    _temporizador?.cancel();
    _temporizador = null;
  }

  Future<void> _consultar() async {
    if (_consultaEmAndamento) return;
    _consultaEmAndamento = true;
    try {
      final respostas = await Future.wait(_preferencias.agencias.map(_perguntar));
      _aplicar(respostas.whereType<_Resposta>().toList());
    } finally {
      _consultaEmAndamento = false;
    }
  }

  /// Pergunta a todas ao mesmo tempo: se uma nao responder, as outras cobrem,
  /// e o painel ainda descobre quais estao no ar.
  Future<_Resposta?> _perguntar(Agencia agencia) async {
    try {
      final dados = await chamarApi(agencia.url, '/bully/lider', tempoLimite: tempoLimiteConsultaLider);
      return _Resposta(agencia.id, dados['liderAtual'] as int?);
    } on SemConexao {
      return null;
    } on ErroApi {
      return null;
    }
  }

  void _aplicar(List<_Resposta> respostas) {
    ativas = respostas.map((r) => r.agencia).toSet();
    if (respostas.isEmpty) {
      status = StatusLideranca.semResposta;
      concordam = 0;
    } else if (_escolherLider(respostas) case final escolhida?) {
      if (lider != null && lider != escolhida) {
        liderAnterior = lider;
        trocaEm = DateTime.now();
      }
      lider = escolhida;
      concordam = respostas.where((r) => r.lider == escolhida).length;
      status = StatusLideranca.definida;
    } else {
      status = StatusLideranca.emEleicao;
      concordam = 0;
    }
    notifyListeners();
  }

  /// Durante uma transicao as agencias podem discordar. Vale quem tem mais votos,
  /// ignorando lider que ja nao responde; no empate, o maior id, como no Bully.
  int? _escolherLider(List<_Resposta> respostas) {
    final votos = <int, int>{};
    for (final resposta in respostas) {
      final candidata = resposta.lider;
      if (candidata != null && ativas.contains(candidata)) {
        votos[candidata] = (votos[candidata] ?? 0) + 1;
      }
    }
    if (votos.isEmpty) return null;
    final ordenadas = votos.entries.toList()
      ..sort((a, b) => b.value != a.value ? b.value - a.value : b.key - a.key);
    return ordenadas.first.key;
  }
}

class _Resposta {
  const _Resposta(this.agencia, this.lider);

  final int agencia;
  final int? lider;
}
