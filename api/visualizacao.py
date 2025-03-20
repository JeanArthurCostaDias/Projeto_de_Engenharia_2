import matplotlib.pyplot as plt
import folium

def gerar_grafico(resultados):
    classes = []

    for key, info in resultados.items():
        for obj in info["deteccoes"]:
            classes.append(obj["nome_classe"])

    # Contagem das classes
    classe_count = {classe: classes.count(classe) for classe in set(classes)}

    # Filtrar classes com pelo menos uma ocorrência
    classes_filtradas = [classe for classe, count in classe_count.items() if count > 0]
    contagem_classes = [classe_count[classe] for classe in classes_filtradas]

    # Gerar gráfico
    plt.figure(figsize=(10, 6))
    plt.bar(classes_filtradas, contagem_classes, color='skyblue', edgecolor='black')
    plt.title("Distribuição das Classes Detectadas")
    plt.xlabel("Classe")
    plt.ylabel("Quantidade")
    plt.xticks(rotation=45)
    plt.grid(True)
    plt.tight_layout()
    plt.savefig("./static/grafico_classes.png")
    plt.close()

def gerar_mapa(resultados):
    m = folium.Map(location=[-1.45502, -48.5024], zoom_start=10)

    for key, info in resultados.items():
        latitude, longitude = info["latitude"], info["longitude"]
        
        # Percorrer as detecções e adicionar um marcador para cada uma
        for deteccao in info['deteccoes']:
            nome_classe = deteccao['nome_classe']
            popup_text = f"Tipo de Lixo Detectado: {nome_classe}"
            
            # Adiciona o marcador com o nome da classe
            folium.Marker([latitude, longitude], popup=popup_text).add_to(m)

    m.save("./static/mapa_localidades.html")
