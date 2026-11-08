import 'dart:convert';

import 'package:path/path.dart' as caminho;
import 'package:sqflite/sqflite.dart';

import 'modelos.dart';

/// Armazenamento local do modo offline-first: ultimo saldo e vetor conhecidos
/// de cada conta, fila de operacoes pendentes e atividade recente.
class BancoLocal {
  BancoLocal._(this._db);

  final Database _db;

  static Future<BancoLocal> abrir() async {
    final db = await openDatabase(
      caminho.join(await getDatabasesPath(), 'iceibank.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE contas (
            id INTEGER PRIMARY KEY,
            nome_aluno TEXT NOT NULL,
            saldo REAL NOT NULL,
            vetor TEXT NOT NULL,
            atualizada_em TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE operacoes_pendentes (
            id TEXT PRIMARY KEY,
            conta_id INTEGER NOT NULL,
            tipo TEXT NOT NULL,
            valor REAL NOT NULL,
            vetor TEXT NOT NULL,
            criada_em TEXT NOT NULL,
            id_destino INTEGER,
            estado TEXT NOT NULL,
            detalhe TEXT
          )''');
        await db.execute('''
          CREATE TABLE atividade (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            conta_id INTEGER NOT NULL,
            tipo TEXT NOT NULL,
            valor REAL NOT NULL,
            em TEXT NOT NULL,
            contraparte INTEGER,
            sincronizada INTEGER NOT NULL
          )''');
      },
    );
    return BancoLocal._(db);
  }

  Future<ContaLocal?> obterConta(int id) async {
    final linhas = await _db.query('contas', where: 'id = ?', whereArgs: [id]);
    return linhas.isEmpty ? null : ContaLocal.deLinha(linhas.first);
  }

  Future<void> salvarConta(ContaLocal conta) =>
      _db.insert('contas', conta.paraLinha(), conflictAlgorithm: ConflictAlgorithm.replace);

  /// Em ordem de criacao: a fila precisa ser reproduzida na ordem em que foi feita.
  Future<List<OperacaoPendente>> listarOperacoes(int contaId) async {
    final linhas = await _db.query(
      'operacoes_pendentes',
      where: 'conta_id = ?',
      whereArgs: [contaId],
      orderBy: 'criada_em, rowid',
    );
    return linhas.map(OperacaoPendente.deLinha).toList();
  }

  Future<void> inserirOperacao(OperacaoPendente operacao) => _db.insert('operacoes_pendentes', operacao.paraLinha());

  Future<void> removerOperacao(String id) => _db.delete('operacoes_pendentes', where: 'id = ?', whereArgs: [id]);

  Future<void> marcarOperacao(String id, EstadoOperacao estado, {String? detalhe}) => _db.update(
        'operacoes_pendentes',
        {'estado': estado.name, 'detalhe': detalhe},
        where: 'id = ?',
        whereArgs: [id],
      );

  /// Depois de uma operacao aplicada, as proximas da fila partem do vetor que a
  /// agencia devolveu: o avanco causado pelo proprio app nao e conflito.
  Future<void> reancorarOperacoes(int contaId, List<int> vetor) => _db.update(
        'operacoes_pendentes',
        {'vetor': jsonEncode(vetor)},
        where: 'conta_id = ?',
        whereArgs: [contaId],
      );

  Future<void> registrarAtividade(int contaId, TipoOperacao tipo, double valor, {int? contraparte, bool sincronizada = false}) =>
      _db.insert('atividade', {
        'conta_id': contaId,
        'tipo': tipo.codigo,
        'valor': valor,
        'em': DateTime.now().toIso8601String(),
        'contraparte': contraparte,
        'sincronizada': sincronizada ? 1 : 0,
      });

  Future<List<ItemAtividade>> listarAtividade(int contaId, {int limite = 20}) async {
    final linhas = await _db.query(
      'atividade',
      where: 'conta_id = ?',
      whereArgs: [contaId],
      orderBy: 'id DESC',
      limit: limite,
    );
    return linhas.map(ItemAtividade.deLinha).toList();
  }
}
