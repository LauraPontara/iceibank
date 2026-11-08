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
  int? consultadaEm;
  DateTime? trocaEm;

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
      _aplicar(await _perguntarAsAgencias());
    } finally {
      _consultaEmAndamento = false;
    }
  }

  /// Tenta as agencias conhecidas em ordem e so desiste depois da ultima.
  Future<_Resposta?> _perguntarAsAgencias() async {
    _Resposta? semLider;
    for (final agencia in _preferencias.agencias) {
      try {
        final dados = await chamarApi(agencia.url, '/bully/lider', tempoLimite: tempoLimiteConsultaLider);
        final resposta = _Resposta(agencia, dados['liderAtual'] as int?);
        if (resposta.lider != null) return resposta;
        semLider = resposta;
      } on SemConexao {
        continue;
      } on ErroApi {
        continue;
      }
    }
    return semLider;
  }

  void _aplicar(_Resposta? resposta) {
    if (resposta == null) {
      status = StatusLideranca.semResposta;
    } else if (resposta.lider == null) {
      status = StatusLideranca.emEleicao;
      consultadaEm = resposta.agencia.id;
    } else {
      if (lider != null && lider != resposta.lider) {
        liderAnterior = lider;
        trocaEm = DateTime.now();
      }
      lider = resposta.lider;
      consultadaEm = resposta.agencia.id;
      status = StatusLideranca.definida;
    }
    notifyListeners();
  }
}

class _Resposta {
  const _Resposta(this.agencia, this.lider);

  final Agencia agencia;
  final int? lider;
}
