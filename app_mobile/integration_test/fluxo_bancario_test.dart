import 'package:flutter_test/flutter_test.dart';
import 'package:iceibank_mobile/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'apoio.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login, saldo, deposito, saque, transferencia e erros da API', (t) async {
    final conta = numeroDeConta(0);
    final destino = numeroDeConta(0);
    await criarConta(conta, 500);
    await criarConta(destino, 0);
    await limparSessao();

    await app.main();
    await t.pump();

    await entrar(t, conta, 'senha-errada');
    await esperar(t, find.text('Credenciais inválidas.'));

    await entrar(t, conta, senhaDeTeste);
    await esperar(t, find.textContaining('500,00'));
    await esperar(t, find.text('Agência 2'));

    await informarValor(t, '50');
    await confirmar(t, 'Depositar');
    await esperar(t, find.textContaining('550,00'));

    await escolherAba(t, 'Sacar');
    await informarValor(t, '1000');
    await confirmar(t, 'Sacar');
    await esperar(t, find.text('Saldo insuficiente.'));

    await informarValor(t, '100,50');
    await confirmar(t, 'Sacar');
    await esperar(t, find.textContaining('449,50'));

    await escolherAba(t, 'Transferir');
    await digitar(t, camposDoFormulario.first, '999999');
    await informarValor(t, '10');
    await confirmar(t, 'Transferir');
    await esperar(t, find.text('Conta de destino não encontrada.'));

    await digitar(t, camposDoFormulario.first, '$destino');
    await informarValor(t, '49,50');
    await confirmar(t, 'Transferir');
    await esperar(t, find.textContaining('400,00'));
  });
}
