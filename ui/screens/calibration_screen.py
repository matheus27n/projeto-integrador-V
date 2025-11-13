from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.clock import Clock
from threading import Thread


class CalibrationScreen(BoxLayout):
    def __init__(self, esp_api, go_back, **kwargs):
        super().__init__(orientation="vertical", padding=20, spacing=15, **kwargs)
        self.esp_api = esp_api
        self.go_back = go_back

        self.title = Label(text="Calibração do ESP32", font_size=22, size_hint_y=None, height=40)
        self.status = Label(text="Selecione uma opção de calibração", font_size=18)

        self.btns = []
        for label, cmd in [
            ("Solo seco (Soil Dry)", "sd"),
            ("Solo úmido (Soil Wet)", "sw"),
            ("Luz Forte", "ll"),
            ("Luz Fraca", "ld"),
        ]:
            b = Button(text=label, size_hint_y=None, height=45)
            b.bind(on_press=lambda _, c=cmd: self.send_command(c))
            self.btns.append(b)

        self.back_btn = Button(text="Voltar", size_hint_y=None, height=45)
        self.back_btn.bind(on_press=lambda _: self.go_back())

        self.add_widget(self.title)
        self.add_widget(self.status)
        for b in self.btns:
            self.add_widget(b)
        self.add_widget(self.back_btn)

    def send_command(self, cmd):
        self.status.text = f"Enviando comando '{cmd}'..."
        Thread(target=self._do_send, args=(cmd,), daemon=True).start()

    def _do_send(self, cmd):
        try:
            result = self.esp_api.calibrate(cmd)
            Clock.schedule_once(lambda dt: self._set_status(f"{result.strip()}"))
        except Exception as e:
            Clock.schedule_once(lambda dt: self._set_status(f"Erro: {str(e)}"))

    def _set_status(self, msg):
        self.status.text = msg
