import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../config/agencias.dart';
import '../dados/api_cliente.dart';
import '../estado/sessao_estado.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import '../widgets/base.dart';
import '../widgets/fundo_ambiente.dart';
import '../widgets/logo.dart';

const tamanhoMinimoNome = 3;
const tamanhoMinimoSenha = 4;

/// Abertura de conta, como a do frontend web: o numero e opcional e define a
/// agencia (id % 3). Ao concluir, a sessao ja entra na conta nova.
class AbrirContaTela extends StatefulWidget {
  const AbrirContaTela({super.key});

  @override
  State<AbrirContaTela> createState() => _AbrirContaTelaState();
}

class _AbrirContaTelaState extends State<AbrirContaTela> {
  final _chave = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  final _numero = TextEditingController();
  bool _senhaVisivel = false;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _senha.dispose();
    _confirmacao.dispose();
    _numero.dispose();
    super.dispose();
  }

  int? get _numeroInformado => int.tryParse(_numero.text.trim());

  Future<void> _abrirConta() async {
    if (!_chave.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context.read<SessaoEstado>().abrirConta(
            nome: _nome.text,
            senha: _senha.text,
            numero: _numeroInformado,
          );
      // Logado ou nao, a conta existe: volta para a raiz, que ja e o painel ou o
      // login com o aviso do que aconteceu.
      if (mounted) Navigator.of(context).pop();
    } on ErroApi catch (e) {
      final emUso = e.status == 409 && _numeroInformado != null;
      if (mounted) setState(() => _erro = emUso ? 'Este número de conta já está em uso.' : e.mensagem);
    } on SemConexao catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String get _rotuloAgencia {
    final numero = _numeroInformado;
    return numero == null
        ? 'Deixe em branco para gerar um número automaticamente.'
        : 'Esta conta ficará na Agência ${agenciaDaConta(numero)}.';
  }

  Widget _botaoVisibilidade(BuildContext context) {
    final t = context.tokens;
    return IconButton(
      tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
      icon: Icon(_senhaVisivel ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: t.mutedForeground),
      onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

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
                            Text('Abra sua conta ICEIBank', style: display(24, espacamento: -0.3, cor: t.foreground)),
                            const SizedBox(height: 4),
                            Text('Sem papelada, sem fila, sem anuidade.', style: corpo(14, cor: t.mutedForeground)),
                            const SizedBox(height: 24),
                            if (_erro != null) ...[
                              Alerta(texto: _erro!),
                              const SizedBox(height: 16),
                            ],
                            Campo(
                              titulo: 'Nome completo',
                              controlador: _nome,
                              dica: 'Ex.: Laura Pontara',
                              teclado: TextInputType.name,
                              validador: (v) => (v ?? '').trim().length < tamanhoMinimoNome
                                  ? 'Informe o nome, com pelo menos $tamanhoMinimoNome letras.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Campo(
                              titulo: 'Senha',
                              controlador: _senha,
                              senha: !_senhaVisivel,
                              sufixo: _botaoVisibilidade(context),
                              validador: (v) => (v ?? '').length < tamanhoMinimoSenha
                                  ? 'A senha precisa ter pelo menos $tamanhoMinimoSenha caracteres.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Campo(
                              titulo: 'Confirmar senha',
                              controlador: _confirmacao,
                              senha: !_senhaVisivel,
                              validador: (v) => v != _senha.text ? 'As senhas não conferem.' : null,
                            ),
                            const SizedBox(height: 16),
                            Campo(
                              titulo: 'Número da conta (opcional)',
                              controlador: _numero,
                              dica: 'Ex.: 1001',
                              teclado: TextInputType.number,
                              aoMudar: (_) => setState(() {}),
                              validador: (v) {
                                final texto = (v ?? '').trim();
                                if (texto.isEmpty) return null;
                                final numero = int.tryParse(texto);
                                return numero == null || numero < 0 ? 'Use apenas números inteiros.' : null;
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(_rotuloAgencia, style: corpo(12, cor: t.mutedForeground)),
                            ),
                            const SizedBox(height: 24),
                            BotaoPrimario(rotulo: 'Criar minha conta', carregando: _carregando, aoTocar: _abrirConta),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _carregando ? null : () => Navigator.of(context).pop(),
                      icon: Icon(LucideIcons.arrowLeft, size: 14, color: t.mutedForeground),
                      label: Text('Já tenho conta', style: corpo(13, cor: t.mutedForeground)),
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
