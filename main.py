from kivy.app import App
from ui.navigation import NavigationManager
from ui.styles import COLORS
from core.esp_api import EspAPI
from core.telemetry_manager import TelemetryManager


class DashboardApp(App):
    def build(self):
        self.title = "ESP Dashboard"

        esp_api = EspAPI(base_url="http://192.168.4.1")
        telemetry_manager = TelemetryManager(esp_api=esp_api)

        return NavigationManager(
            telemetry_manager=telemetry_manager,
            esp_api=esp_api
        )

if __name__ == "__main__":
    DashboardApp().run()
