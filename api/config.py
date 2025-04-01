import os
from firebase_admin import credentials, initialize_app, firestore
from ultralytics import YOLO

def configurar_firebase():
    cred = credentials.Certificate(os.path.join("token","app-residuos-3a6b8-firebase-adminsdk-fbsvc-6cb3e52b8d.json"))
    firebase_app = initialize_app(cred)
    db = firestore.client()
    return db

def carregar_modelo():
    caminho_modelo = os.path.join(os.path.dirname(__file__),"model","modelo_yolo11_3.pt")
    model = YOLO(caminho_modelo)
    return model
