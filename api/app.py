from flask import Flask, jsonify, render_template
from firebase_admin import firestore
from api.config import configurar_firebase
from api.inferencia import inferir_em_imagens
from api.visualizacao import gerar_grafico, gerar_mapa
import os
import json

# Inicializar Firebase
db = configurar_firebase()
img_ref = db.collection("images")
resultados_path = "resultados_inferencia.json"
app = Flask(__name__)
@app.route("/")
def hello_world():
    return "<p>Hello, World!</p>"

@app.route("/dados", methods=["GET"])
def get_dados():
    try:
        imagens = img_ref.stream()
        dados = {doc.id: doc.to_dict() for doc in imagens}
        return jsonify(dados), 200
    except Exception as e:
        return jsonify({"erro": str(e)}), 500

@app.route("/inferencia", methods=["GET"])
def executar_inferencia():
    try:
        imagens = img_ref.stream()
        dados = {doc.id: doc.to_dict() for doc in imagens}
        
        if os.path.exists(resultados_path):
            # Carregar os resultados do arquivo
            with open(resultados_path, "r") as file:
                resultados = json.load(file)
        else:
            # Inferir nas imagens
            resultados = inferir_em_imagens(dados)
            
            # Salvar os resultados em um arquivo JSON
            with open(resultados_path, "w") as file:
                json.dump(resultados, file)

        # Gerar gráfico e mapa
        gerar_grafico(resultados)
        gerar_mapa(resultados)

        return jsonify({"status": "Inferência concluída com sucesso"}), 200

    except Exception as e:
        return jsonify({"erro": str(e)}), 500


@app.route("/dashboard")
def tabela_resultados():
    try:
        imagens = img_ref.stream()
        dados = {doc.id: doc.to_dict() for doc in imagens}

        # Inferir nas imagens
        if os.path.exists(resultados_path):
            # Carregar os resultados do arquivo
            with open(resultados_path, "r") as file:
                resultados = json.load(file)
        else:
            return jsonify({"erro": "Realize a inferência antes de acessar o dashboard"}), 400
        # Organizar os dados para a tabela
        tabela_dados = []
        for key, info in resultados.items():
            for obj in info['deteccoes']:
                tabela_dados.append({
                    "latitude": info["latitude"],
                    "longitude": info["longitude"],
                    "classe": obj["nome_classe"],
                    "confianca": obj["confianca"],
                })

        # Passar os dados para o template
        return render_template("tabela_resultados.html", tabela_dados=tabela_dados, resultados=resultados)

    except Exception as e:
        return jsonify({"erro": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True)
