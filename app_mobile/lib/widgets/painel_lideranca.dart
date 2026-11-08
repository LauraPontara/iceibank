import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    return Superficie(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LÍDER ATUAL', style: rotulo(t.mutedForeground)),
              ChipStatus(texto: comLider ? 'Consenso' : 'Sem consenso', desligado: !comLider),
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
          if (estado.liderAnterior != null && estado.trocaEm != null) ...[
            const SizedBox(height: 12),
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
        StatusLideranca.definida => ('Agência ${estado.lider}', 'Informado pela Agência ${estado.consultadaEm}. Atualiza sozinho a cada 3 segundos.'),
        StatusLideranca.emEleicao => ('Em eleição', 'A Agência ${estado.consultadaEm} ainda não conhece uma líder.'),
        StatusLideranca.semResposta => ('Sem resposta', 'Nenhuma das 3 agências respondeu. Tentando de novo.'),
      };
}
