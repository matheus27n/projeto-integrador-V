from kivy.clock import Clock
from time import time
from core.esp_api import EspAPI

COOLDOWN_MS = 5 * 60 * 1000  # 5 minutos


class TelemetryManager:
    def __init__(self, esp_api: EspAPI, callback=None, poll_interval=1.0):
        self.esp_api = esp_api
        self.callback = callback
        self.poll_interval = poll_interval

        self.last_data = None
        self.last_error = {"tipo": None, "timestamp": 0}
        self.is_fetching = False
        self.timer = None

    def start(self):
        self.stop()
        self.timer = Clock.schedule_interval(self._tick, self.poll_interval)

    def stop(self):
        if self.timer:
            self.timer.cancel()
            self.timer = None

    def _tick(self, dt):
        if self.is_fetching:
            return
        self.is_fetching = True

        try:
            data = self.esp_api.get_telemetry()
            self.last_data = data
            if self.callback:
                self.callback(data, None)
        except Exception as e:
            self._handle_error(str(e))
        finally:
            self.is_fetching = False

    def _handle_error(self, message):
        tipo = "outro"
        msg_lower = message.lower()

        if "offline" in msg_lower or "network" in msg_lower or "falha" in msg_lower:
            tipo = "esp_offline"
            user_msg = "Não foi possível conectar ao ESP32. Verifique a conexão Wi-Fi."
        elif "timeout" in msg_lower:
            tipo = "timeout"
            user_msg = "A comunicação com o ESP32 demorou demais e foi interrompida."
        elif "json" in msg_lower:
            tipo = "parse_error"
            user_msg = "Os dados recebidos do ESP32 estão em formato inválido."
        elif "cors" in msg_lower:
            tipo = "cors_error"
            user_msg = "Falha de comunicação devido a restrições CORS."
        else:
            user_msg = message

        now = time() * 1000
        if self.last_error["tipo"] == tipo and now - self.last_error["timestamp"] < COOLDOWN_MS:
            print(f"[Cooldown ativo] Ignorando erro repetido: {user_msg}")
            return

        self.last_error = {"tipo": tipo, "timestamp": now}
        print(f"[LOG ERROR] {tipo}: {user_msg}")
        if self.callback:
            self.callback(None, user_msg)

    def get_latest_data(self):
        return self.last_data
