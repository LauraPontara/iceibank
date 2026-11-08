import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../estado/conta_estado.dart';
import '../estado/lideranca_estado.dart';
import '../estado/preferencias.dart';
import '../estado/sessao_estado.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import '../util/formato.dart';
import '../widgets/base.dart';
import '../widgets/cartao_metal.dart';
import '../widgets/cartao_pendencias.dart';
import '../widgets/formulario_operacao.dart';
import '../widgets/fundo_ambiente.dart';
import '../widgets/lista_atividade.dart';
import '../widgets/logo.dart';
import '../widgets/painel_lideranca.dart';

class PainelTela extends StatefulWidget {
  const PainelTela({super.key});

  @override
  State<PainelTela> createState() => _PainelTelaState();
}

class _PainelTelaState extends State<PainelTela> with WidgetsBindingObserver {
  late final ContaEstado _conta = context.read<ContaEstado>();
  late final LiderancaEstado _lideranca = context.read<LiderancaEstado>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _retomar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _conta.limpar();
    _lideranca.parar();
    super.dispose();
  }

  void _retomar() {
    _conta.iniciar();
    _lideranca.iniciar();
  }

  // Em segundo plano o app para de consultar a rede para poupar bateria
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) {
      _retomar();
    } else if (estado == AppLifecycleState.paused) {
      _conta.parar();
      _lideranca.parar();
    }
  }

  Future<void> _sair() async {
    final sessao = context.read<SessaoEstado>();
    final quantidade = _conta.operacoes.length;
    if (quantidade > 0) {
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (contexto) => AlertDialog(
          title: const Text('Sair com operações pendentes?'),
          content: Text('$quantidade ${quantidade == 1 ? 'operação fica guardada' : 'operações ficam guardadas'} neste aparelho e voltam a sincronizar no próximo login desta conta.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(contexto, true), child: const Text('Sair')),
          ],
        ),
      );
      if (confirmado != true) return;
    }
    await sessao.encerrar();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final estado = context.watch<ContaEstado>();
    final sessao = context.watch<SessaoEstado>();
    final preferencias = context.read<Preferencias>();
    final conta = estado.conta;
    final contaId = sessao.sessao?.contaId;
    if (contaId == null) return const SizedBox.shrink();
    final primeiroNome = conta?.nomeAluno.split(' ').first;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FundoAmbiente(
        child: SafeArea(
          child: RefreshIndicator(
            color: t.primary,
            onRefresh: estado.atualizar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                Row(
                  children: [
                    const LogoMarca(),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Alternar tema',
                      onPressed: preferencias.alternarTema,
                      icon: Icon(preferencias.temaClaro ? LucideIcons.moon : LucideIcons.sun, size: 18, color: t.mutedForeground),
                    ),
                    IconButton(
                      tooltip: 'Sair',
                      onPressed: _sair,
                      icon: Icon(LucideIcons.logOut, size: 18, color: t.mutedForeground),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(primeiroNome == null ? 'OLÁ' : 'OLÁ, ${primeiroNome.toUpperCase()}', style: rotulo(t.mutedForeground, tamanho: 12)),
                const SizedBox(height: 4),
                Text('Minha conta', style: display(32, espacamento: -0.5, cor: t.foreground)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChipStatus(texto: sessao.agencia.nome, desligado: estado.semConexao),
                    ChipStatus(texto: 'Conta $contaId', semPonto: true, monoespacado: true),
                    if (estado.semConexao) const ChipStatus(texto: 'Offline', desligado: true),
                  ],
                ),
                const SizedBox(height: 24),
                if (estado.semConexao) ...[
                  Alerta(
                    tipo: TipoAlerta.info,
                    texto: conta == null
                        ? 'Sem conexão com a agência.'
                        : 'Sem conexão com a agência. Mostrando o último dado conhecido, de ${formatarDataHora(conta.atualizadaEm)}.',
                  ),
                  const SizedBox(height: 16),
                ],
                if (estado.avisoSincronizacao != null) ...[
                  Alerta(tipo: TipoAlerta.sucesso, texto: estado.avisoSincronizacao!),
                  const SizedBox(height: 16),
                ],
                if (estado.erro != null) ...[
                  Alerta(texto: estado.erro!),
                  const SizedBox(height: 16),
                ],
                Center(
                  child: CartaoMetal(
                    titular: conta?.nomeAluno ?? 'Titular',
                    conta: contaId,
                    saldo: estado.saldoExibido,
                    rotuloSaldo: estado.temPendentes ? 'Saldo provisório' : 'Saldo',
                  ),
                ),
                const SizedBox(height: 24),
                const CartaoPendencias(),
                const PainelLideranca(),
                const SizedBox(height: 16),
                const FormularioOperacao(),
                const SizedBox(height: 16),
                ListaAtividade(itens: estado.atividade),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
