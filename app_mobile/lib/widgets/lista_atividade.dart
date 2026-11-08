import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../dados/modelos.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import '../util/formato.dart';
import 'base.dart';

const _icones = {
  TipoOperacao.deposito: LucideIcons.arrowDownToLine,
  TipoOperacao.saque: LucideIcons.arrowUpFromLine,
  TipoOperacao.transferencia: LucideIcons.arrowLeftRight,
};

class ListaAtividade extends StatelessWidget {
  const ListaAtividade({super.key, required this.itens});

  final List<ItemAtividade> itens;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Superficie(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Atividade recente', style: display(18, cor: t.foreground)),
          const SizedBox(height: 4),
          Text('Operações feitas neste aparelho.', style: corpo(12, cor: t.mutedForeground)),
          const SizedBox(height: 8),
          if (itens.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Nenhuma movimentação ainda. Faça um depósito para começar.', style: corpo(14, cor: t.mutedForeground)),
            ),
          for (final (indice, item) in itens.indexed) ...[
            if (indice > 0) Divider(height: 1, color: t.border),
            _Linha(item: item),
          ],
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.item});

  final ItemAtividade item;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final positivo = item.tipo == TipoOperacao.deposito;
    final detalhes = [
      formatarDataHora(item.em),
      if (item.contraparte != null) 'conta ${item.contraparte}',
      if (item.sincronizada) 'offline',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: t.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(_icones[item.tipo], size: 16, color: t.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.tipo.rotulo, style: corpo(14, peso: 500, cor: t.foreground)),
                Text(detalhes, style: mono(11, cor: t.mutedForeground)),
              ],
            ),
          ),
          Text(
            '${positivo ? '+' : '−'} ${formatarMoeda(item.valor)}',
            style: mono(14, cor: positivo ? t.primary : t.mutedForeground),
          ),
        ],
      ),
    );
  }
}
