import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ErroApi implements Exception {
  ErroApi(this.status, this.mensagem, [this.dados = const {}]);

  final int status;
  final String mensagem;
  final Map<String, dynamic> dados;

  @override
  String toString() => mensagem;
}

/// A agencia nao foi alcancada (sem rede, fora do ar ou demorou demais).
class SemConexao implements Exception {
  SemConexao(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

const tempoLimitePadrao = Duration(seconds: 4);

Future<Map<String, dynamic>> chamarApi(
  String agenciaUrl,
  String caminho, {
  String metodo = 'GET',
  Map<String, dynamic>? corpo,
  String? token,
  Duration tempoLimite = tempoLimitePadrao,
}) async {
  final cabecalhos = {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
  final uri = Uri.tryParse('$agenciaUrl$caminho');
  if (uri == null) throw SemConexao('O endereço da agência é inválido.');

  final http.Response resposta;
  try {
    final requisicao = metodo == 'POST'
        ? http.post(uri, headers: cabecalhos, body: jsonEncode(corpo))
        : http.get(uri, headers: cabecalhos);
    resposta = await requisicao.timeout(tempoLimite);
  } on SocketException {
    throw SemConexao('Não foi possível contatar a agência. Ela está no ar?');
  } on TimeoutException {
    throw SemConexao('A agência demorou demais para responder.');
  } on http.ClientException {
    throw SemConexao('A conexão com a agência foi interrompida.');
  }

  final dados = _decodificar(resposta);
  if (resposta.statusCode >= 200 && resposta.statusCode < 300) return dados;

  final detalhe = dados['detail'];
  final mensagem = dados['erro'] ?? (detalhe is String ? detalhe : null);
  throw ErroApi(
    resposta.statusCode,
    mensagem as String? ?? (detalhe != null ? 'Dados inválidos. Confira os campos.' : 'Erro ${resposta.statusCode}'),
    dados,
  );
}

Map<String, dynamic> _decodificar(http.Response resposta) {
  try {
    final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
    return dados is Map<String, dynamic> ? dados : {};
  } on FormatException {
    return {};
  }
}
