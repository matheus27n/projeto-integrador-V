from kivy.clock import Clock
from kivy.uix.screenmanager import ScreenManager, Screen, FadeTransition
from ui.screens.dashboard_screen import DashboardScreen
from ui.screens.calibration_screen import CalibrationScreen
from ui.screens.error_screen import ErrorScreen


class NavigationManager(ScreenManager):
    def __init__(self, telemetry_manager, esp_api, **kwargs):
        super().__init__(transition=FadeTransition(duration=0.3), **kwargs)

        self.telemetry_manager = telemetry_manager
        self.esp_api = esp_api
        self.connection_timeout_event = None  

        self.dashboard = Screen(name="dashboard")
        self.calibration = Screen(name="calibration")
        self.error = Screen(name="error")

        self.add_widget(self.dashboard)
        self.add_widget(self.calibration)
        self.add_widget(self.error)

        self._build_dashboard()
        self.current = "dashboard"

    def _build_dashboard(self):
        self.dashboard.clear_widgets()
        self.dashboard.add_widget(
            DashboardScreen(
                telemetry_manager=self.telemetry_manager,
                go_to_calibration=self.show_calibration,
                connect_to_esp=self.try_connect,  
            )
        )

    def _build_calibration(self):
        self.calibration.clear_widgets()
        self.calibration.add_widget(
            CalibrationScreen(
                esp_api=self.esp_api,
                go_back=self.show_dashboard,
            )
        )

    def _build_error(self, message):
        self.error.clear_widgets()
        self.error.add_widget(
            ErrorScreen(
                error_message=message,
                go_back=self.show_dashboard,
            )
        )

    def try_connect(self):
        """Tenta conectar ao ESP32 e define timeout de 5s."""
        print("🔌 Tentando conectar ao ESP32...")

        self.connection_timeout_event = Clock.schedule_once(self._on_connection_timeout, 5)

        try:
            success = self.telemetry_manager.test_connection()
            if success:
                print("✅ Conectado ao ESP32!")
                if self.connection_timeout_event:
                    self.connection_timeout_event.cancel()
            else:
                self.show_error("Não foi possível conectar ao ESP32.")
        except Exception as e:
            self.show_error(f"Erro na conexão: {e}")

    def _on_connection_timeout(self, dt):
        print("Tempo de conexão esgotado.")
        self.show_error("Tempo limite atingido: ESP32 não encontrado.")

    def show_dashboard(self, *args):
        self._build_dashboard()
        self.current = "dashboard"

    def show_calibration(self, *args):
        self._build_calibration()
        self.current = "calibration"

    def show_error(self, message="Erro desconhecido"):
        self._build_error(message)
        self.current = "error"
