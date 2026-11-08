import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/agencias.dart';
import '../estado/lideranca_estado.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import '../util/formato.dart';
import 'base.dart';

class PainelLideranca extends StatelessWidget {
  const PainelLideranca({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final estado = context.watch<LiderancaEstado>();
    final (titulo, detalhe) = _textos(estado);
    final comLider = estado.status == StatusLideranca.definida;
    final unanime = comLider && estado.concordam == estado.ativas.length;

    return Superficie(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LÍDER ATUAL', style: rotulo(t.mutedForeground)),
              ChipStatus(texto: unanime ? 'Consenso' : (comLider ? 'Em transição' : 'Sem líder'), desligado: !unanime),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (filho, animacao) => FadeTransition(
              opacity: animacao,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(animacao),
                child: filho,
              ),
            ),
            child: Text(
              titulo,
              key: ValueKey(titulo),
              style: display(28, espacamento: -0.4, cor: comLider ? t.primary : t.foreground),
            ),
          ),
          const SizedBox(height: 4),
          Text(detalhe, style: corpo(13, cor: t.mutedForeground, altura: 1.4)),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var id = 0; id < numeroAgencias; id++) ...[
                if (id > 0) const SizedBox(width: 8),
                Expanded(child: _IndicadorAgencia(id: id, ativa: estado.ativas.contains(id), lider: comLider && estado.lider == id)),
              ],
            ],
          ),
          if (estado.liderAnterior != null && estado.trocaEm != null) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: t.border),
            const SizedBox(height: 12),
            Text(
              'Última troca: Agência ${estado.liderAnterior} → Agência ${estado.lider}, às ${formatarHora(estado.trocaEm!)}',
              style: mono(11, cor: t.mutedForeground),
            ),
          ],
        ],
      ),
    );
  }

  (String, String) _textos(LiderancaEstado estado) => switch (estado.status) {
        StatusLideranca.consultando => ('Consultando...', 'Perguntando às agências quem é a líder.'),
        StatusLideranca.definida => (
            'Agência ${estado.lider}',
            '${estado.concordam} de ${estado.ativas.length} agências ativas concordam. Atualiza sozinho a cada 3 segundos.',
          ),
        StatusLideranca.emEleicao => ('Em eleição', 'As agências ativas ainda não conhecem uma líder.'),
        StatusLideranca.semResposta => ('Sem resposta', 'Nenhuma das 3 agências respondeu. Tentando de novo.'),
      };
}

/// Funcionalidade adicional do Sprint 3: quais agencias estao respondendo agora.
class _IndicadorAgencia extends StatelessWidget {
  const _IndicadorAgencia({required this.id, required this.ativa, required this.lider});

  final int id;
  final bool ativa;
  final bool lider;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final situacao = lider ? 'Líder' : (ativa ? 'Ativa' : 'Fora do ar');
    return Semantics(
      label: 'Agência $id: $situacao',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: lider ? t.primary.withValues(alpha: 0.1) : t.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: lider ? t.primary.withValues(alpha: 0.4) : t.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: ativa ? t.primary : t.destructive),
                ),
                const SizedBox(width: 6),
                Text('Ag. $id', style: mono(12, peso: 500, cor: t.foreground)),
              ],
            ),
            const SizedBox(height: 4),
            Text(situacao, style: corpo(12, cor: ativa ? t.mutedForeground : t.destructive)),
          ],
        ),
      ),
    );
  }
}
