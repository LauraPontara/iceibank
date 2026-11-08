import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../dados/api_cliente.dart';
import '../dados/banco_local.dart';
import '../dados/modelos.dart';
import '../util/formato.dart';
import 'sessao_estado.dart';

/// Tambem e o intervalo de nova tentativa da fila: a conectividade do celular
/// nao avisa quando so a agencia voltou, com o Wi-Fi ligado o tempo todo.
const intervaloAtualizacaoSaldo = Duration(seconds: 5);
const duracaoAvisoSincronizacao = Duration(seconds: 12);

class ResultadoOperacao {
  const ResultadoOperacao(this.mensagem, {this.pendente = false});

  final String mensagem;
  final bool pendente;
}

class ContaEstado extends ChangeNotifier {
  ContaEstado(this._sessao, this._banco);

  final SessaoEstado _sessao;
  final BancoLocal _banco;

  Timer? _temporizador;
  Timer? _temporizadorAviso;
  StreamSubscription<List<ConnectivityResult>>? _conectividade;
  Future<void> _cauda = Future.value();
  bool _atualizacaoNaFila = false;

  ContaLocal? conta;
  List<OperacaoPendente> operacoes = const [];
  List<ItemAtividade> atividade = const [];
  bool semConexao = false;
  String? erro;
  String? avisoSincronizacao;

  bool get temPendentes => operacoes.any((o) => o.estado == EstadoOperacao.pendente);

  /// UI otimista: saldo real conhecido mais o efeito esperado da fila.
  double? get saldoExibido {
    final atual = conta;
    if (atual == null) return null;
    return operacoes
        .where((o) => o.estado == EstadoOperacao.pendente)
        .fold<double>(atual.saldo, (saldo, o) => saldo + o.efeito);
  }

  Future<void> iniciar() async {
    final sessao = _sessao.sessao;
    if (sessao == null) return;
    conta = await _banco.obterConta(sessao.contaId);
    await _recarregarListas(sessao.contaId);
    notifyListeners();
    _temporizador ??= Timer.periodic(intervaloAtualizacaoSaldo, (_) => atualizar());
    _conectividade ??= Connectivity().onConnectivityChanged.listen(_aoMudarConectividade);
    await atualizar();
  }

  void parar() {
    _temporizador?.cancel();
    _temporizador = null;
    _conectividade?.cancel();
    _conectividade = null;
  }

  void limpar() {
    parar();
    _temporizadorAviso?.cancel();
    conta = null;
    operacoes = const [];
    atividade = const [];
    semConexao = false;
    erro = null;
    avisoSincronizacao = null;
  }

  void _aoMudarConectividade(List<ConnectivityResult> resultados) {
    if (resultados.every((r) => r == ConnectivityResult.none)) {
      semConexao = true;
      notifyListeners();
    } else {
      atualizar();
    }
  }

  /// Leituras, escritas e sincronizacao rodam uma de cada vez: uma resposta
  /// antiga nao pode sobrescrever o cache depois de uma operacao mais nova.
  Future<T> _emSerie<T>(Future<T> Function() acao) {
    final resultado = _cauda.then((_) => acao());
    _cauda = resultado.then<void>((_) {}, onError: (_) {});
    return resultado;
  }

  Future<void> atualizar() async {
    if (_atualizacaoNaFila) return;
    _atualizacaoNaFila = true;
    await _emSerie(() async {
      _atualizacaoNaFila = false;
      await _lerContaDaAgencia();
      await _sincronizarFila();
      notifyListeners();
    });
  }

  Future<void> _lerContaDaAgencia() async {
    final sessao = _sessao.sessao;
    if (sessao == null) return;
    try {
      final dados = await chamarApi(_sessao.agencia.url, '/contas/${sessao.contaId}', token: sessao.token);
      await _guardarConta(ContaLocal.deJson(dados, vetorDeJson(dados['vetorAtual'])));
      semConexao = false;
      erro = null;
    } on SemConexao {
      semConexao = true;
    } on ErroApi catch (e) {
      if (e.status == 401) {
        await _encerrarSessaoExpirada();
      } else {
        erro = e.mensagem;
      }
    }
  }

  Future<void> _guardarConta(ContaLocal nova) async {
    conta = nova;
    await _banco.salvarConta(nova);
  }

  Future<void> _recarregarListas(int contaId) async {
    operacoes = await _banco.listarOperacoes(contaId);
    atividade = await _banco.listarAtividade(contaId);
  }

  Future<void> _encerrarSessaoExpirada() async {
    final quantidade = operacoes.length;
    await _sessao.encerrar(
      aviso: quantidade == 0
          ? 'Sessão expirada. Faça login novamente.'
          : 'Sessão expirada. Entre de novo para sincronizar $quantidade ${quantidade == 1 ? 'operação pendente' : 'operações pendentes'}.',
    );
  }

  Future<ResultadoOperacao> depositar(double valor) => _executar(TipoOperacao.deposito, valor);

  Future<ResultadoOperacao> sacar(double valor) => _executar(TipoOperacao.saque, valor);

  Future<ResultadoOperacao> transferir(int idDestino, double valor) =>
      _executar(TipoOperacao.transferencia, valor, idDestino: idDestino);

  Future<ResultadoOperacao> _executar(TipoOperacao tipo, double valor, {int? idDestino}) => _emSerie(() async {
        final chave = const Uuid().v4();
        // Com fila existente a operacao entra atras dela, para manter a ordem
        if (operacoes.isNotEmpty) return _enfileirar(chave, tipo, valor, idDestino);
        try {
          return await _executarNaAgencia(chave, tipo, valor, idDestino);
        } on SemConexao {
          semConexao = true;
          return _enfileirar(chave, tipo, valor, idDestino);
        } on ErroApi catch (e) {
          if (e.status == 401) await _encerrarSessaoExpirada();
          rethrow;
        }
      });

  Future<ResultadoOperacao> _executarNaAgencia(String chave, TipoOperacao tipo, double valor, int? idDestino) async {
    final sessao = _sessao.sessao!;
    final url = _sessao.agencia.url;
    final String mensagem;
    switch (tipo) {
      case TipoOperacao.deposito:
        await chamarApi(url, '/contas/${sessao.contaId}/depositar', metodo: 'POST', corpo: {'valor': valor}, token: sessao.token);
        mensagem = 'Depósito de ${formatarMoeda(valor)} concluído.';
      case TipoOperacao.saque:
        await chamarApi(url, '/contas/${sessao.contaId}/sacar', metodo: 'POST', corpo: {'valor': valor}, token: sessao.token);
        mensagem = 'Saque de ${formatarMoeda(valor)} concluído.';
      case TipoOperacao.transferencia:
        final resultado = await chamarApi(
          url,
          '/transferencias',
          metodo: 'POST',
          token: sessao.token,
          corpo: {'idOrigem': sessao.contaId, 'idDestino': idDestino, 'valor': valor, 'idempotencyKey': chave},
        );
        mensagem = resultado['mensagem'] as String;
    }
    await _banco.registrarAtividade(sessao.contaId, tipo, valor, contraparte: idDestino);
    await _lerContaDaAgencia();
    await _recarregarListas(sessao.contaId);
    notifyListeners();
    return ResultadoOperacao(mensagem);
  }

  Future<ResultadoOperacao> _enfileirar(String chave, TipoOperacao tipo, double valor, int? idDestino) async {
    final atual = conta;
    if (atual == null) throw SemConexao('Sem conexão e sem dados locais desta conta.');
    if (tipo != TipoOperacao.deposito && valor > saldoExibido!) {
      throw ErroApi(400, 'Saldo provisório insuficiente para esta operação.');
    }
    await _banco.inserirOperacao(OperacaoPendente(
      id: chave,
      contaId: atual.id,
      tipo: tipo,
      valor: valor,
      idDestino: idDestino,
      vetor: atual.vetor,
      criadaEm: DateTime.now(),
    ));
    await _recarregarListas(atual.id);
    notifyListeners();
    return ResultadoOperacao('${tipo.rotulo} de ${formatarMoeda(valor)} guardado, pendente de sincronização.', pendente: true);
  }

  /// Reproduz a fila em ordem. Um conflito bloqueia as operacoes seguintes ate
  /// a pessoa decidir, porque elas foram feitas contando com a que falhou.
  Future<void> _sincronizarFila() async {
    final sessao = _sessao.sessao;
    if (sessao == null) return;
    var sincronizadas = 0;

    while (_sessao.sessao != null) {
      await _recarregarListas(sessao.contaId);
      if (operacoes.any((o) => o.estado == EstadoOperacao.conflito)) break;
      final proxima = operacoes.where((o) => o.estado == EstadoOperacao.pendente).firstOrNull;
      if (proxima == null) break;

      try {
        final resposta = await chamarApi(
          _sessao.agencia.url,
          '/contas/${sessao.contaId}/sincronizar',
          metodo: 'POST',
          token: sessao.token,
          corpo: {
            'tipo': proxima.tipo.codigo,
            'valor': proxima.valor,
            'vetorConhecido': proxima.vetor,
            'idDestino': proxima.idDestino,
            'idempotencyKey': proxima.id,
          },
        );
        await _aoAplicar(proxima, resposta);
        sincronizadas++;
      } on SemConexao {
        semConexao = true;
        break;
      } on ErroApi catch (e) {
        if (e.status == 401) {
          await _encerrarSessaoExpirada();
          break;
        }
        if (e.status == 409 && e.dados.containsKey('vetorAtual')) {
          await _aoConflitar(proxima, e);
          break;
        }
        // Fora do conflito, erro 4xx nao muda ao tentar de novo. O resto e passageiro.
        if (e.status == 423 || e.status >= 500) break;
        await _banco.marcarOperacao(proxima.id, EstadoOperacao.rejeitada, detalhe: e.mensagem);
      }
    }

    if (_sessao.sessao != null) await _recarregarListas(sessao.contaId);
    if (sincronizadas > 0) {
      _avisar(sincronizadas == 1 ? 'Operação pendente sincronizada.' : '$sincronizadas operações pendentes sincronizadas.');
    }
  }

  Future<void> _aoAplicar(OperacaoPendente operacao, Map<String, dynamic> resposta) async {
    await _banco.removerOperacao(operacao.id);
    await _banco.registrarAtividade(operacao.contaId, operacao.tipo, operacao.valor, contraparte: operacao.idDestino, sincronizada: true);
    semConexao = false;

    // Uma transferencia concluida antes por outro caminho devolve so a mensagem
    if (resposta.containsKey('vetorAtual')) {
      final vetor = vetorDeJson(resposta['vetorAtual']);
      await _guardarConta(ContaLocal.deJson(resposta, vetor));
      await _banco.reancorarOperacoes(operacao.contaId, vetor);
    } else {
      await _lerContaDaAgencia();
      await _banco.reancorarOperacoes(operacao.contaId, conta!.vetor);
    }
  }

  Future<void> _aoConflitar(OperacaoPendente operacao, ErroApi conflito) async {
    final vetor = vetorDeJson(conflito.dados['vetorAtual']);
    await _guardarConta(ContaLocal.deJson(conflito.dados['contaAtual'] as Map<String, dynamic>, vetor));
    await _banco.marcarOperacao(operacao.id, EstadoOperacao.conflito, detalhe: conflito.mensagem);
    semConexao = false;
  }

  void _avisar(String mensagem) {
    avisoSincronizacao = mensagem;
    _temporizadorAviso?.cancel();
    _temporizadorAviso = Timer(duracaoAvisoSincronizacao, () {
      avisoSincronizacao = null;
      notifyListeners();
    });
  }

  /// A pessoa viu o saldo real e pediu para aplicar mesmo assim.
  Future<void> reaplicar(OperacaoPendente operacao) => _emSerie(() async {
        await _banco.reancorarOperacoes(operacao.contaId, conta!.vetor);
        await _banco.marcarOperacao(operacao.id, EstadoOperacao.pendente);
        await _sincronizarFila();
        notifyListeners();
      });

  Future<void> descartar(OperacaoPendente operacao) => _emSerie(() async {
        await _banco.removerOperacao(operacao.id);
        if (conta != null) await _banco.reancorarOperacoes(operacao.contaId, conta!.vetor);
        await _recarregarListas(operacao.contaId);
        await _sincronizarFila();
        notifyListeners();
      });
}
