from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.clock import Clock


class DashboardScreen(BoxLayout):
    def __init__(self, telemetry_manager, go_to_calibration, connect_to_esp, **kwargs):
        super().__init__(orientation="vertical", padding=20, spacing=15, **kwargs)

        self.telemetry_manager = telemetry_manager
        self.go_to_calibration = go_to_calibration
        self.connect_to_esp = connect_to_esp

        self.title = Label(
            text="Dashboard - Telemetria ESP32",
            font_size=22,
            size_hint_y=None,
            height=40,
        )

        self.status_label = Label(
            text="Status: Desconectado",
            font_size=18,
            size_hint_y=None,
            height=35,
        )

        self.data_label = Label(
            text="Aguardando conexão...",
            font_size=16,
            halign="center",
        )

        self.connect_btn = Button(
            text="Conectar ao ESP32",
            size_hint_y=None,
            height=45,
        )
        self.connect_btn.bind(on_press=lambda _: self._start_connection())

        self.refresh_btn = Button(
            text="Atualizar Dados",
            size_hint_y=None,
            height=45,
        )
        self.refresh_btn.bind(on_press=lambda _: self.update_data())

        self.calibrate_btn = Button(
            text="Calibrar Sensores",
            size_hint_y=None,
            height=45,
        )
        self.calibrate_btn.bind(on_press=lambda _: self.go_to_calibration())

        self.add_widget(self.title)
        self.add_widget(self.status_label)
        self.add_widget(self.data_label)
        self.add_widget(self.connect_btn)
        self.add_widget(self.refresh_btn)
        self.add_widget(self.calibrate_btn)


    def _start_connection(self):
        self.status_label.text = "Conectando ao ESP32..."
        self.data_label.text = "Tentando comunicação..."
        self.connect_to_esp()

        Clock

    