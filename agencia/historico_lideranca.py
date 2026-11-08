import json
import os

TIPOS_BULLY = ["ELEICAO_INICIADA", "ELEICAO_RECEBIDA", "TORNOU_LIDER", "LIDER_ANUNCIADO", "LIDER_NAO_RESPONDEU"]

pasta_dados = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
if not os.path.isdir(pasta_dados):
    raise SystemExit("Pasta data/ não encontrada. Rode as agências para gerar os logs de eventos.")
arquivos = [f for f in os.listdir(pasta_dados) if f.endswith(".jsonl")]

eventos = []
for arquivo in arquivos:
    with open(os.path.join(pasta_dados, arquivo), "r", encoding="utf-8") as f:
        for linha in f:
            linha = linha.strip()
            if linha:
                eventos.append(json.loads(linha))

eventos_bully = [e for e in eventos if e["tipo"] in TIPOS_BULLY]
eventos_bully.sort(key=lambda e: e["horaParede"])

print("=== Histórico de eventos de eleição ===")
for evento in eventos_bully:
    print(f"({evento['horaParede']}) [{evento['agencia']}] {evento['tipo']} {json.dumps(evento['detalhes'], ensure_ascii=False)}")

print("\n=== Linha do tempo de líderes ===")
for evento in eventos_bully:
    if evento["tipo"] == "TORNOU_LIDER":
        print(f"A partir de {evento['horaParede']}: Agência {evento['detalhes']['idAgencia']} é a líder")
