import json
import os

pasta_dados = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
arquivos = [f for f in os.listdir(pasta_dados) if f.endswith(".jsonl")]

todos_eventos = []
for arquivo in arquivos:
    with open(os.path.join(pasta_dados, arquivo), "r", encoding="utf-8") as f:
        for linha in f:
            linha = linha.strip()
            if linha:
                todos_eventos.append(json.loads(linha))

todos_eventos.sort(key=lambda e: e["timestampLamport"])

print("=== Linha do tempo unificada (ordenada por relogio de Lamport) ===")
for evento in todos_eventos:
    print(
        f"[Lamport {evento['timestampLamport']}] ({evento['horaParede']}) "
        f"{evento['agencia']} - {evento['tipo']} {json.dumps(evento['detalhes'], ensure_ascii=False)}"
    )
