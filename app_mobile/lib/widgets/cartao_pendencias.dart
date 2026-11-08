import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../dados/modelos.dart';
import '../estado/conta_estado.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import '../util/formato.dart';
import 'base.dart';

/// Mostra tudo o que ainda nao esta confirmado pela agencia. Conflito e rejeicao
/// ficam visiveis ate a pessoa decidir: nada e aplicado ou apagado em silencio.
class CartaoPendencias extends StatelessWidget {
  const CartaoPendencias({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final operacoes = context.watch<ContaEstado>().operacoes;
    if (operacoes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Superficie(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Pendente de sincronização', style: display(18, cor: t.foreground))),
                ChipStatus(texto: '${operacoes.length}', semPonto: true, monoespacado: true),
              ],
            ),
            const SizedBox(height: 4),
            for (final (indice, operacao) in operacoes.indexed) ...[
              if (indice > 0) Divider(height: 1, color: t.border),
              _LinhaOperacao(operacao: operacao),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinhaOperacao extends StatelessWidget {
  const _LinhaOperacao({required this.operacao});

  final OperacaoPendente operacao;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final negativo = operacao.tipo != TipoOperacao.deposito;
    final contraparte = operacao.idDestino == null ? '' : ' · conta ${operacao.idDestino}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icone, size: 16, color: _emErro ? t.destructive : t.mutedForeground),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(operacao.tipo.rotulo, style: corpo(14, peso: 500, cor: t.foreground)),
                    Text('$_situacao$contraparte', style: mono(11, cor: t.mutedForeground)),
                  ],
                ),
              ),
              Text('${negativo ? '−' : '+'} ${formatarMoeda(operacao.valor)}', style: mono(14, cor: t.mutedForeground)),
            ],
          ),
          if (operacao.estado == EstadoOperacao.conflito) _Conflito(operacao: operacao),
          if (operacao.estado == EstadoOperacao.rejeitada) _Rejeicao(operacao: operacao),
        ],
      ),
    );
  }

  bool get _emErro => operacao.estado != EstadoOperacao.pendente;

  IconData get _icone => switch (operacao.estado) {
        EstadoOperacao.pendente => LucideIcons.clock,
        EstadoOperacao.conflito => LucideIcons.triangleAlert,
        EstadoOperacao.rejeitada => LucideIcons.circleX,
      };

  String get _situacao => switch (operacao.estado) {
        EstadoOperacao.pendente => 'Aguardando sincronização',
        EstadoOperacao.conflito => 'Conflito detectado',
        EstadoOperacao.rejeitada => 'Recusada pela agência',
      };
}

class _Conflito extends StatelessWidget {
  const _Conflito({required this.operacao});

  final OperacaoPendente operacao;

  @override
  Widget build(BuildContext context) {
    final estado = context.read<ContaEstado>();
    final saldoReal = context.watch<ContaEstado>().conta?.saldo ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Alerta(
            texto: 'A conta mudou enquanto o app estava offline, então esta operação não foi aplicada automaticamente. '
                'Saldo real agora: ${formatarMoeda(saldoReal)}.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BotaoFantasma(rotulo: 'Aplicar sobre o saldo real', cor: context.tokens.primary, aoTocar: () => estado.reaplicar(operacao)),
              BotaoFantasma(rotulo: 'Descartar', aoTocar: () => estado.descartar(operacao)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Rejeicao extends StatelessWidget {
  const _Rejeicao({required this.operacao});

  final OperacaoPendente operacao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Alerta(texto: operacao.detalhe ?? 'A agência recusou esta operação.'),
          const SizedBox(height: 12),
          BotaoFantasma(rotulo: 'Dispensar', aoTocar: () => context.read<ContaEstado>().descartar(operacao)),
        ],
      ),
    );
  }
}
