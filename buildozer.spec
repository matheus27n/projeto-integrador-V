[app]
# Nome e versão do aplicativo
title = ESP Dashboard
package.name = esp_dashboard
package.domain = org.thalys
version = 1.0.0

# Arquivo principal (onde está a classe DashboardApp)
source.main = main.py

# Caminho do diretório com o código
source.dir = .

# Ícone opcional (pode adicionar depois)
# icon.filename = assets/icon.png

# Módulos Python necessários
requirements = python3, kivy==2.3.0, requests

# Se usar JSON, Threading ou Serial (pyserial), adicione:
# requirements = python3, kivy==2.3.0, requests, pyserial

# Permite Internet (necessário se o app consulta o ESP)
android.permissions = INTERNET

# Orientação da tela
orientation = portrait

# Idioma padrão
android.entrypoint = org.kivy.android.PythonActivity
android.presplash_color = #000000
android.api = 33
android.minapi = 27
android.sdk = 33
android.ndk = 25b
android.archs = arm64-v8a, armeabi-v7a

# Para não incluir arquivos desnecessários
exclude_dirs = tests, bin, build, __pycache__

# Nome do pacote (APK)
package.filename = ESP_Dashboard

[buildozer]
log_level = 2
warn_on_root = 1
