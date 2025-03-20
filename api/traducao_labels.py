import os
def carregar_traducoes():
    traducoes = {}
    caminho_labels = os.path.join(os.path.dirname(__file__),"traducao", 'labels_ptbr.txt')
    with open(caminho_labels, 'r', encoding='utf-8') as file:
        for line in file:
            index, classe = line.strip().split(' - ', 1)
            traducoes[int(index)] = classe
    return traducoes
