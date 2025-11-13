from kivy.uix.image import Image
from kivy.animation import Animation
from kivy.clock import Clock


class LoadingSpinner(Image):
    def __init__(self, source="assets/spinner.png", duration=1.2, **kwargs):
        super().__init__(source=source, **kwargs)
        self.duration = duration
        self.size_hint = (None, None)
        self.size = (60, 60)
        self.allow_stretch = True
        self.keep_ratio = True
        Clock.schedule_once(self.start_animation, 0)

    def start_animation(self, *_):
        anim = Animation(angle=360, duration=self.duration)
        anim.bind(on_complete=lambda *_: self.start_animation())
        anim.start(self)