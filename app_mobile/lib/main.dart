import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'dados/banco_local.dart';
import 'estado/conta_estado.dart';
import 'estado/lideranca_estado.dart';
import 'estado/preferencias.dart';
import 'estado/sessao_estado.dart';
import 'telas/login_tela.dart';
import 'telas/painel_tela.dart';
import 'tema/tema_app.dart';
import 'tema/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final preferencias = await Preferencias.carregar();
  final sessao = SessaoEstado(preferencias);
  await sessao.restaurar();
  final banco = await BancoLocal.abrir();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: preferencias),
      ChangeNotifierProvider.value(value: sessao),
      ChangeNotifierProvider(create: (_) => ContaEstado(sessao, banco)),
      ChangeNotifierProvider(create: (_) => LiderancaEstado(preferencias)),
    ],
    child: const IceiBankApp(),
  ));
}

class IceiBankApp extends StatelessWidget {
  const IceiBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    final temaClaro = context.watch<Preferencias>().temaClaro;
    final logado = context.watch<SessaoEstado>().sessao != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (temaClaro ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light).copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: MaterialApp(
        title: 'ICEIBank',
        debugShowCheckedModeBanner: false,
        theme: criarTema(Tokens.claro, Brightness.light),
        darkTheme: criarTema(Tokens.escuro, Brightness.dark),
        themeMode: temaClaro ? ThemeMode.light : ThemeMode.dark,
        home: logado ? const PainelTela() : const LoginTela(),
      ),
    );
  }
}
