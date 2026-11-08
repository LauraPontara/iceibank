import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:iceibank_mobile/config/agencias.dart';

/// Precisa das 3 agencias no ar, acessiveis em hostPadrao.
const senhaDeTeste = 'senha-do-teste';

String urlDaAgencia(int id) => 'http://$hostPadrao:${portaBase + id}';

int numeroDeConta(int agencia) => (Random().nextInt(300000) + 1000) * numeroAgencias + agencia;

Future<void> criarConta(int id, double saldo) async {
  final resposta = await http.post(
    Uri.parse('${urlDaAgencia(agenciaDaConta(id))}/contas'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'id': id, 'nomeAluno': 'Teste Integracao', 'senha': senhaDeTeste, 'saldoInicial': saldo}),
  );
  expect(resposta.statusCode, 201, reason: resposta.body);
}

Future<void> limparSessao() => const FlutterSecureStorage().deleteAll();

/// O fundo tem animacao continua, entao pumpAndSettle nunca terminaria.
Future<void> esperar(WidgetTester t, Finder alvo, {int segundos = 20}) async {
  final limite = DateTime.now().add(Duration(seconds: segundos));
  while (DateTime.now().isBefore(limite)) {
    await t.pump(const Duration(milliseconds: 200));
    if (alvo.evaluate().isNotEmpty) return;
  }
  final textos = find.byType(Text, skipOffstage: false).evaluate().map((e) => (e.widget as Text).data).join(' | ');
  fail('Não apareceu em $segundos segundos: $alvo\nNa tela: $textos');
}

Future<void> entrar(WidgetTester t, int conta, String senha) async {
  await esperar(t, find.text('Acessar minha conta'));
  await digitar(t, find.byType(TextFormField).at(0), '$conta');
  await digitar(t, find.byType(TextFormField).at(1), senha);
  await t.tap(find.text('Entrar'));
}

/// Escreve direto no controlador: o enterText abre o teclado real do celular, que
/// redimensiona a tela enquanto anima e devolve o campo vazio ao fechar.
Future<void> digitar(WidgetTester t, Finder campo, String texto) async {
  t.widget<TextFormField>(campo).controller!.text = texto;
  await t.pump(const Duration(milliseconds: 100));
}

/// A lista so considera "em tela" o que esta visivel, e o formulario fica no fim dela.
Future<void> tocarVisivel(WidgetTester t, Finder alvo) async {
  await t.ensureVisible(alvo);
  await t.pump(const Duration(milliseconds: 300));
  await t.tap(alvo, warnIfMissed: false);
  await t.pump(const Duration(milliseconds: 300));
}

Future<void> escolherAba(WidgetTester t, String aba) => tocarVisivel(t, find.text(aba, skipOffstage: false).first);

Finder get camposDoFormulario => find.byType(TextFormField, skipOffstage: false);

/// O campo de valor e sempre o ultimo do formulario.
Future<void> informarValor(WidgetTester t, String valor) async {
  await digitar(t, camposDoFormulario.last, valor);
}

Future<void> confirmar(WidgetTester t, String rotulo) async {
  await tocarVisivel(t, find.text(rotulo, skipOffstage: false).last);
  await irAoTopo(t);
}

/// O saldo, os avisos e as pendencias ficam no topo, e a lista so monta o que esta perto da tela.
Future<void> irAoTopo(WidgetTester t) async {
  t.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
  await t.pump(const Duration(milliseconds: 300));
}
