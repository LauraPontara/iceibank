import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../config/agencias.dart';
import '../dados/api_cliente.dart';
import '../estado/preferencias.dart';
import '../estado/sessao_estado.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import '../widgets/base.dart';
import '../widgets/fundo_ambiente.dart';
import '../widgets/logo.dart';

class LoginTela extends StatefulWidget {
  const LoginTela({super.key});

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> {
  final _chave = GlobalKey<FormState>();
  final _conta = TextEditingController();
  final _senha = TextEditingController();
  bool _senhaVisivel = false;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _conta.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_chave.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context.read<SessaoEstado>().entrar(int.parse(_conta.text), _senha.text);
    } on ErroApi catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } on SemConexao catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _editarServidor() async {
    final preferencias = context.read<Preferencias>();
    final campo = TextEditingController(text: preferencias.host);
    final novo = await showDialog<String>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Endereço das agências'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('IP do computador na mesma rede Wi-Fi do celular.'),
            const SizedBox(height: 16),
            TextField(controller: campo, keyboardType: TextInputType.url, autofocus: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexto), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(contexto, campo.text), child: const Text('Salvar')),
        ],
      ),
    );
    if (novo != null && novo.trim().isNotEmpty) await preferencias.definirHost(novo);
  }

  String get _rotuloAgencia {
    final conta = int.tryParse(_conta.text);
    return conta == null ? 'Agência definida pelo número da conta' : 'Agência ${agenciaDaConta(conta)} (automática)';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final aviso = context.watch<SessaoEstado>().avisoLogin;
    final host = context.watch<Preferencias>().host;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FundoAmbiente(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    const LogoMarca(tamanho: 40),
                    const SizedBox(height: 32),
                    Superficie(
                      child: Form(
                        key: _chave,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Acessar minha conta', style: display(24, espacamento: -0.3, cor: t.foreground)),
                            const SizedBox(height: 4),
                            Text('Entre com o número da conta e a senha.', style: corpo(14, cor: t.mutedForeground)),
                            const SizedBox(height: 24),
                            if (aviso != null || _erro != null) ...[
                              Alerta(texto: _erro ?? aviso!),
                              const SizedBox(height: 16),
                            ],
                            Campo(
                              titulo: 'Número da conta',
                              controlador: _conta,
                              dica: 'Ex.: 1001',
                              teclado: TextInputType.number,
                              aoMudar: (_) => setState(() {}),
                              validador: (v) => int.tryParse(v ?? '') == null ? 'Informe o número da conta.' : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(_rotuloAgencia, style: corpo(12, cor: t.mutedForeground)),
                            ),
                            const SizedBox(height: 16),
                            Campo(
                              titulo: 'Senha',
                              controlador: _senha,
                              senha: !_senhaVisivel,
                              validador: (v) => (v ?? '').isEmpty ? 'Informe a senha.' : null,
                              sufixo: IconButton(
                                tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
                                icon: Icon(_senhaVisivel ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: t.mutedForeground),
                                onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                              ),
                            ),
                            const SizedBox(height: 24),
                            BotaoPrimario(rotulo: 'Entrar', carregando: _carregando, aoTocar: _entrar),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _editarServidor,
                      icon: Icon(LucideIcons.server, size: 14, color: t.mutedForeground),
                      label: Text('Agências em $host', style: mono(12, cor: t.mutedForeground)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
