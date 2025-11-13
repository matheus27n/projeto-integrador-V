import requests
from typing import Optional


class EspAPI:
    def __init__(self, base_url: str):
        if not base_url.startswith("http"):
            raise ValueError("A URL base do ESP deve começar com http:// ou https://")
        self.base_url = base_url.rstrip("/")
    
    def get_telemetry(self) -> dict:
        try:
            response = requests.get(f"{self.base_url}/data", timeout=5)
            response.raise_for_status()
            data = response.json()

            if "soil_raw" not in data:
                raise ValueError("Dados inválidos recebidos do ESP32.")

            return data

        except requests.exceptions.ConnectionError:
            raise ConnectionError("ESP32 offline ou inacessível.")
        except requests.exceptions.Timeout:
            raise TimeoutError("A requisição ao ESP32 expirou.")
        except ValueError as e:
            raise ValueError(f"Erro de formatação de dados: {e}")
        except Exception as e:
            raise RuntimeError(f"Erro desconhecido: {e}")

    def calibrate(self, type_: str) -> str:
        try:
            response = requests.get(f"{self.base_url}/cal?type={type_}", timeout=5)
            response.raise_for_status()
            return response.text
        except Exception as e:
            raise RuntimeError(f"Falha ao calibrar ({type_}): {e}")