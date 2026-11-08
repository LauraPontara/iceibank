import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../config/agencias.dart';
import '../dados/api_cliente.dart';
import '../estado/conta_estado.dart';
import '../estado/sessao_estado.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import '../util/formato.dart';
import 'base.dart';

enum _Aba { deposito, saque, transferencia }

const _rotulos = {_Aba.deposito: 'Depositar', _Aba.saque: 'Sacar', _Aba.transferencia: 'Transferir'};
const _icones = {
  _Aba.deposito: LucideIcons.arrowDownToLine,
  _Aba.saque: LucideIcons.arrowUpFromLine,
  _Aba.transferencia: LucideIcons.arrowLeftRight,
};

class FormularioOperacao extends StatefulWidget {
  const FormularioOperacao({super.key});

  @override
  State<FormularioOperacao> createState() => _FormularioOperacaoState();
}

class _FormularioOperacaoState extends State<FormularioOperacao> {
  final _chave = GlobalKey<FormState>();
  final _valor = TextEditingController();
  final _destino = TextEditingController();
  _Aba _aba = _Aba.deposito;
  bool _carregando = false;

  @override
  void dispose() {
    _valor.dispose();
    _destino.dispose();
    super.dispose();
  }

  String? _validarValor(String? texto) {
    final valor = lerValor(texto ?? '');
    if (valor == null || valor <= 0) return 'Informe um valor maior que zero.';
    return null;
  }

  String? _validarDestino(String? texto) {
    final destino = int.tryParse(texto ?? '');
    if (destino == null || destino < 0) return 'Informe o número da conta.';
    if (destino == context.read<SessaoEstado>().sessao!.contaId) return 'Escolha uma conta diferente da sua.';
    return null;
  }

  Future<void> _confirmar() async {
    if (!_chave.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final estado = context.read<ContaEstado>();
    final valor = lerValor(_valor.text)!;
    setState(() => _carregando = true);
    try {
      final mensagem = switch (_aba) {
        _Aba.deposito => await estado.depositar(valor).then((_) => 'Depósito de ${formatarMoeda(valor)} concluído.'),
        _Aba.saque => await estado.sacar(valor).then((_) => 'Saque de ${formatarMoeda(valor)} concluído.'),
        _Aba.transferencia => await estado.transferir(int.parse(_destino.text), valor),
      };
      if (!mounted) return;
      _valor.clear();
      _destino.clear();
      mostrarAviso(context, mensagem, tipo: TipoAlerta.sucesso);
    } on ErroApi catch (e) {
      if (mounted && e.status != 401) mostrarAviso(context, e.mensagem);
    } on SemConexao catch (e) {
      if (mounted) mostrarAviso(context, e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Widget? _dicaRota() {
    final destino = int.tryParse(_destino.text);
    if (destino == null) return null;
    final mesma = agenciaDaConta(destino) == agenciaDaConta(context.read<SessaoEstado>().sessao!.contaId);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        mesma ? 'Mesma agência' : 'Transferência entre agências',
        style: corpo(12, cor: context.tokens.mutedForeground),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Superficie(
      child: Form(
        key: _chave,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Movimentar dinheiro', style: display(18, cor: t.foreground)),
            const SizedBox(height: 16),
            _Abas(selecionada: _aba, aoEscolher: (aba) => setState(() => _aba = aba)),
            const SizedBox(height: 20),
            if (_aba == _Aba.transferencia) ...[
              Campo(
                titulo: 'Conta de destino',
                controlador: _destino,
                dica: 'Ex.: 1002',
                teclado: TextInputType.number,
                validador: _validarDestino,
                aoMudar: (_) => setState(() {}),
              ),
              ?_dicaRota(),
              const SizedBox(height: 16),
            ],
            Campo(
              titulo: 'Valor (R\$)',
              controlador: _valor,
              dica: '0,00',
              teclado: const TextInputType.numberWithOptions(decimal: true),
              destaque: true,
              validador: _validarValor,
            ),
            const SizedBox(height: 24),
            BotaoPrimario(rotulo: _rotulos[_aba]!, carregando: _carregando, aoTocar: _confirmar),
          ],
        ),
      ),
    );
  }
}

class _Abas extends StatelessWidget {
  const _Abas({required this.selecionada, required this.aoEscolher});

  final _Aba selecionada;
  final ValueChanged<_Aba> aoEscolher;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduzido = MediaQuery.disableAnimationsOf(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: t.secondary, borderRadius: BorderRadius.circular(14)),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              alignment: Alignment(-1.0 + selecionada.index * 1.0, 0),
              duration: reduzido ? Duration.zero : const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: FractionallySizedBox(
                widthFactor: 1 / _Aba.values.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: t.primary.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 8), spreadRadius: -10)],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final aba in _Aba.values)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: aba == selecionada,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => aoEscolher(aba),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: _RotuloAba(aba: aba, ativa: aba == selecionada),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RotuloAba extends StatelessWidget {
  const _RotuloAba({required this.aba, required this.ativa});

  final _Aba aba;
  final bool ativa;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cor = ativa ? t.primaryForeground : t.mutedForeground;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_icones[aba], size: 15, color: cor),
        const SizedBox(width: 6),
        Flexible(child: Text(_rotulos[aba]!, style: corpo(13, peso: 500, cor: cor), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
