import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:iceibank_mobile/config/agencias.dart';
import 'package:iceibank_mobile/estado/preferencias.dart';
import 'package:iceibank_mobile/main.dart' as app;
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'apoio.dart';

/// Apontar o app para o proprio celular faz a agencia ficar inalcancavel,
/// sem depender do modo aviao, que este teste nao consegue ligar.
Future<void> ficarOffline(WidgetTester t) => _preferencias(t).definirHost('127.0.0.1');

Future<void> ficarOnline(WidgetTester t) => _preferencias(t).definirHost(hostPadrao);

Preferencias _preferencias(WidgetTester t) => t.element(find.byType(Scaffold).first).read<Preferencias>();

Future<void> depositarPorFora(int conta, double valor) async {
  final url = urlDaAgencia(agenciaDaConta(conta));
  final login = await http.post(
    Uri.parse('$url/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'id': conta, 'senha': senhaDeTeste}),
  );
  final token = jsonDecode(login.body)['accessToken'];
  final resposta = await http.post(
    Uri.parse('$url/contas/$conta/depositar'),
    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    body: jsonEncode({'valor': valor}),
  );
  expect(resposta.statusCode, 200, reason: resposta.body);
}

Future<void> depositar(WidgetTester t, String valor) async {
  await informarValor(t, valor);
  await confirmar(t, 'Depositar');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('fila offline, sincronizacao automatica e conflito', (t) async {
    final conta = numeroDeConta(1);
    await criarConta(conta, 100);
    await limparSessao();

    await app.main();
    await t.pump();
    await entrar(t, conta, senhaDeTeste);
    await esperar(t, find.textContaining('100,00'));

    // Duas operacoes offline: a segunda so passa se a fila reancorar o vetor
    await ficarOffline(t);
    await esperar(t, find.text('Offline'));
    await depositar(t, '10');
    await esperar(t, find.text('Pendente de sincronização'));
    await esperar(t, find.textContaining('110,00'));
    await esperar(t, find.text('SALDO PROVISÓRIO'));
    await depositar(t, '5');
    await esperar(t, find.textContaining('115,00'));

    await ficarOnline(t);
    await esperar(t, find.text('2 operações pendentes sincronizadas.'));
    await esperar(t, find.text('SALDO'));
    expect(find.text('Pendente de sincronização', skipOffstage: false), findsNothing);

    // Conflito: a conta muda por outro caminho enquanto o app esta offline
    await ficarOffline(t);
    await esperar(t, find.text('Offline'));
    await depositar(t, '20');
    await esperar(t, find.textContaining('135,00'));
    await depositarPorFora(conta, 1000);

    await ficarOnline(t);
    await esperar(t, find.text('Conflito detectado'));
    await esperar(t, find.textContaining('Saldo real agora: R\$ 1.115,00'));

    await tocarVisivel(t, find.text('Aplicar sobre o saldo real', skipOffstage: false));
    await irAoTopo(t);
    await esperar(t, find.text('Operação pendente sincronizada.'));
    await esperar(t, find.textContaining('1.135,00'));

    // Descartar: o saldo real fica como esta e a fila esvazia
    await ficarOffline(t);
    await esperar(t, find.text('Offline'));
    await depositar(t, '7');
    await depositarPorFora(conta, 1);
    await ficarOnline(t);
    await esperar(t, find.text('Conflito detectado'));
    await tocarVisivel(t, find.text('Descartar', skipOffstage: false));
    await irAoTopo(t);
    await esperar(t, find.textContaining('1.136,00'));
    expect(find.text('Conflito detectado', skipOffstage: false), findsNothing);
  });
}
