import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iceibank_mobile/main.dart' as app;
import 'package:iceibank_mobile/telas/abrir_conta_tela.dart';
import 'package:integration_test/integration_test.dart';

import 'apoio.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('abre conta pelo app, recusa numero em uso e entra na conta nova', (t) async {
    final emUso = numeroDeConta(1);
    final nova = numeroDeConta(1);
    await criarConta(emUso, 0);
    await limparSessao();

    await app.main();
    await t.pump();

    await esperar(t, find.text('Acessar minha conta'));
    await t.tap(find.text('Ainda não tem conta? Abra a sua'));
    await esperar(t, find.text('Abra sua conta ICEIBank'));

    // O login continua montado por baixo da tela nova, entao busca so os campos dela.
    final campos = find.descendant(of: find.byType(AbrirContaTela), matching: find.byType(TextFormField));
    await digitar(t, campos.at(0), 'Conta pelo App');
    await digitar(t, campos.at(1), senhaDeTeste);
    await digitar(t, campos.at(2), 'outra-senha');
    await digitar(t, campos.at(3), '$emUso');
    await esperar(t, find.text('Esta conta ficará na Agência 1.'));
    await tocarVisivel(t, find.text('Criar minha conta'));
    await esperar(t, find.text('As senhas não conferem.'));

    await digitar(t, campos.at(2), senhaDeTeste);
    await tocarVisivel(t, find.text('Criar minha conta'));
    await esperar(t, find.text('Este número de conta já está em uso.'));

    await digitar(t, campos.at(3), '$nova');
    await tocarVisivel(t, find.text('Criar minha conta'));
    await esperar(t, find.text('Conta $nova'));
    await esperar(t, find.textContaining('0,00'));
  });
}
