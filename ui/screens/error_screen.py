from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button


class ErrorScreen(BoxLayout):
    def __init__(self, error_message, go_back, **kwargs):
        super().__init__(orientation="vertical", padding=20, spacing=15, **kwargs)

        self.title = Label(text="Erro de Conexão", font_size=22, size_hint_y=None, height=40)
        self.message = Label(text=str(error_message or "Erro desconhecido"), font_size=18)
        self.back_btn = Button(text="Voltar", size_hint_y=None, height=45)
        self.back_btn.bind(on_press=lambda _: go_back())

        self.add_widget(self.title)
        self.add_widget(self.message)
        self.add_widget(self.back_btn)
