import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "src"))

from services.relogio_vetorial import comparar_vetores

pasta_dados = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
if not os.path.isdir(pasta_dados):
    raise SystemExit("Pasta data/ não encontrada. Rode as agências para gerar os logs de eventos.")
arquivos = [f for f in os.listdir(pasta_dados) if f.endswith(".jsonl")]

todos_eventos = []
for arquivo in arquivos:
    with open(os.path.join(pasta_dados, arquivo), "r", encoding="utf-8") as f:
        for linha in f:
            linha = linha.strip()
            if linha:
                todos_eventos.append(json.loads(linha))

todos_eventos.sort(key=lambda e: e["horaParede"])

print("=== Linha do tempo (ordenada por hora de parede) ===")
for evento in todos_eventos:
    print(
        f"[{evento['agencia']}] vetor={evento['timestampVetorial']} {evento['tipo']} "
        f"{json.dumps(evento['detalhes'], ensure_ascii=False)}"
    )

print("\n=== Pares de eventos CONCORRENTES entre agências diferentes ===")
encontrou_concorrente = False
for i, e1 in enumerate(todos_eventos):
    for e2 in todos_eventos[i + 1:]:
        if e1["agencia"] == e2["agencia"]:
            continue
        if comparar_vetores(e1["timestampVetorial"], e2["timestampVetorial"]) == "CONCORRENTES":
            encontrou_concorrente = True
            print(
                f"[{e1['agencia']}] {e1['tipo']} ({e1['timestampVetorial']}) x "
                f"[{e2['agencia']}] {e2['tipo']} ({e2['timestampVetorial']})"
            )

if not encontrou_concorrente:
    print("(nenhum par concorrente encontrado nesta execução - gere mais eventos em paralelo e rode de novo)")
