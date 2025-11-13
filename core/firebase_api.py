
import requests
import json

FIREBASE_BASE = "https://seu-projeto-default-rtdb.firebaseio.com"

def save_telemetry(data: dict):
    try:
        url = f"{FIREBASE_BASE}/telemetria.json"
        res = requests.post(url, json=data)
        res.raise_for_status()
        return res.json()
    except Exception as e:
        raise RuntimeError(f"Erro ao salvar no Firebase: {e}")

def get_history():
    try:
        url = f"{FIREBASE_BASE}/telemetria.json"
        res = requests.get(url)
        res.raise_for_status()
        return res.json() or {}
    except Exception as e:
        raise RuntimeError(f"Erro ao buscar histórico: {e}")
