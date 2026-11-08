import 'dart:convert';

class ContaLocal {
  const ContaLocal({
    required this.id,
    required this.nomeAluno,
    required this.saldo,
    required this.vetor,
    required this.atualizadaEm,
  });

  final int id;
  final String nomeAluno;
  final double saldo;
  final List<int> vetor;
  final DateTime atualizadaEm;

  /// Aceita a resposta de GET /contas/{id} e o campo contaAtual do 409, que vem sem vetor.
  factory ContaLocal.deJson(Map<String, dynamic> json, List<int> vetor) => ContaLocal(
        id: json['id'] as int,
        nomeAluno: json['nomeAluno'] as String,
        saldo: (json['saldo'] as num).toDouble(),
        vetor: vetor,
        atualizadaEm: DateTime.now(),
      );

  factory ContaLocal.deLinha(Map<String, Object?> linha) => ContaLocal(
        id: linha['id'] as int,
        nomeAluno: linha['nome_aluno'] as String,
        saldo: linha['saldo'] as double,
        vetor: vetorDeTexto(linha['vetor'] as String),
        atualizadaEm: DateTime.parse(linha['atualizada_em'] as String),
      );

  Map<String, Object?> paraLinha() => {
        'id': id,
        'nome_aluno': nomeAluno,
        'saldo': saldo,
        'vetor': jsonEncode(vetor),
        'atualizada_em': atualizadaEm.toIso8601String(),
      };
}

List<int> vetorDeJson(Object? valor) => (valor as List).cast<int>();

List<int> vetorDeTexto(String texto) => vetorDeJson(jsonDecode(texto));

enum TipoOperacao {
  deposito('DEPOSITO', 'Depósito'),
  saque('SAQUE', 'Saque'),
  transferencia('TRANSFERENCIA', 'Transferência enviada');

  const TipoOperacao(this.codigo, this.rotulo);

  final String codigo;
  final String rotulo;

  static TipoOperacao deCodigo(String codigo) => values.firstWhere((t) => t.codigo == codigo);
}

enum EstadoOperacao { pendente, conflito, rejeitada }

class OperacaoPendente {
  const OperacaoPendente({
    required this.id,
    required this.contaId,
    required this.tipo,
    required this.valor,
    required this.vetor,
    required this.criadaEm,
    this.idDestino,
    this.estado = EstadoOperacao.pendente,
    this.detalhe,
  });

  /// Tambem e a chave de idempotencia enviada ao sincronizar.
  final String id;
  final int contaId;
  final TipoOperacao tipo;
  final double valor;
  final List<int> vetor;
  final DateTime criadaEm;
  final int? idDestino;
  final EstadoOperacao estado;
  final String? detalhe;

  /// Efeito esperado no saldo, usado na UI otimista.
  double get efeito => tipo == TipoOperacao.deposito ? valor : -valor;

  factory OperacaoPendente.deLinha(Map<String, Object?> linha) => OperacaoPendente(
        id: linha['id'] as String,
        contaId: linha['conta_id'] as int,
        tipo: TipoOperacao.deCodigo(linha['tipo'] as String),
        valor: linha['valor'] as double,
        vetor: vetorDeTexto(linha['vetor'] as String),
        criadaEm: DateTime.parse(linha['criada_em'] as String),
        idDestino: linha['id_destino'] as int?,
        estado: EstadoOperacao.values.byName(linha['estado'] as String),
        detalhe: linha['detalhe'] as String?,
      );

  Map<String, Object?> paraLinha() => {
        'id': id,
        'conta_id': contaId,
        'tipo': tipo.codigo,
        'valor': valor,
        'vetor': jsonEncode(vetor),
        'criada_em': criadaEm.toIso8601String(),
        'id_destino': idDestino,
        'estado': estado.name,
        'detalhe': detalhe,
      };
}

class ItemAtividade {
  const ItemAtividade({required this.tipo, required this.valor, required this.em, this.contraparte, this.sincronizada = false});

  final TipoOperacao tipo;
  final double valor;
  final DateTime em;
  final int? contraparte;
  final bool sincronizada;

  factory ItemAtividade.deLinha(Map<String, Object?> linha) => ItemAtividade(
        tipo: TipoOperacao.deCodigo(linha['tipo'] as String),
        valor: linha['valor'] as double,
        em: DateTime.parse(linha['em'] as String),
        contraparte: linha['contraparte'] as int?,
        sincronizada: linha['sincronizada'] == 1,
      );
}
