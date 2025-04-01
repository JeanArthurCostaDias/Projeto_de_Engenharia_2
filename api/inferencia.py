import cv2
import numpy as np
import requests
from api.config import carregar_modelo
from api.traducao_labels import carregar_traducoes  # O arquivo labels.py será mostrado em seguida

model = carregar_modelo()
traducoes = carregar_traducoes()

def baixar_imagem(url):
    resposta = requests.get(url)
    if resposta.status_code == 200:
        arr = np.asarray(bytearray(resposta.content), dtype=np.uint8)
        return cv2.imdecode(arr, cv2.IMREAD_COLOR)
    else:
        print(f"Erro ao baixar imagem: {url}")
        return None

def salvar_imagem_com_deteccao(imagem, deteccoes, caminho_imagem):
    for det in deteccoes:
        for box in det.boxes:
            classe = int(box.cls[0])
            nome_classe = model.names[classe]
            confianca = float(box.conf[0])
            x1, y1, x2, y2 = map(int, box.xyxy[0])

            # Desenhar a caixa na imagem
            cv2.rectangle(imagem, (x1, y1), (x2, y2), (0, 255, 0), 2)
            cv2.putText(imagem, f'{nome_classe} {confianca:.2f}', (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

    # Salvar a imagem
    cv2.imwrite(caminho_imagem, imagem)

def inferir_em_imagens(dados):
    resultados = {}
    for key, info in dados.items():
        url = info["imageUrl"]
        latitude, longitude = info["latitude"], info["longitude"]

        imagem = baixar_imagem(url)
        if imagem is None:
            continue
        imagem = cv2.resize(imagem, (1024, 1024))
        imagem_ajustada = imagem.copy()
        deteccoes = model(imagem)

        # Salvar a imagem com as detecções
        caminho_imagem_com_deteccao = f"./static/deteccao_{key}.jpg"
        salvar_imagem_com_deteccao(imagem_ajustada, deteccoes, caminho_imagem_com_deteccao)
        nomes_classes = model.names
        objetos_detectados = []
        for det in deteccoes:
            for box in det.boxes:
                classe = int(box.cls[0])  # Classe detectada (índice)
                nome_classe = nomes_classes[classe]  # Nome da classe usando o índice
                nome_classe = traducoes.get(classe, nome_classe)  # Traduzir para português

                confianca = float(box.conf[0])  # Confiança da detecção
                x1, y1, x2, y2 = map(int, box.xyxy[0])  # Coordenadas do bounding box

                objetos_detectados.append({
                    "nome_classe": nome_classe,
                    "confianca": confianca,
                    "bbox": [x1, y1, x2, y2]
                })

        # Guardar resultados
        resultados[key] = {
            "latitude": latitude,
            "longitude": longitude,
            "deteccoes": objetos_detectados,
            "imagem_com_deteccao": caminho_imagem_com_deteccao
        }

    return resultados
