from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from ui.styles import COLORS, FONTS, LAYOUT


class TelemetryCard(BoxLayout):
    def __init__(self, title, value="--", unit="", color="primary", **kwargs):
        super().__init__(orientation="vertical", padding=LAYOUT["padding"] / 2, spacing=4, **kwargs)
        self.size_hint_y = None
        self.height = 100
        self.radius = [12]
        self.md_bg_color = COLORS.get(color, COLORS["primary"]) 
        self.title_text = title
        self.value_text = value
        self.unit_text = unit
        self.color = color

        self.title_label = Label(
            text=title,
            font_size=FONTS["small_size"],
            color=COLORS["text"],
            halign="center"
        )

        self.value_label = Label(
            text=str(value),
            font_size=FONTS["title_size"],
            color=COLORS["primary"],
            bold=True,
            halign="center"
        )

        self.unit_label = Label(
            text=unit,
            font_size=FONTS["small_size"],
            color=COLORS["secondary"],
            halign="center"
        )

        self.add_widget(self.title_label)
        self.add_widget(self.value_label)
        self.add_widget(self.unit_label)

    def update_value(self, new_value):
        self.value_label.text = str(new_value)