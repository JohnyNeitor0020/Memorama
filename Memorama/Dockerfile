# Etapa 1: Descargar Godot y preparar el proyecto
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias necesarias para Godot headless
RUN apt-get update && apt-get install -y \
    ca-certificates \
    wget \
    unzip \
    libfontconfig1 \
    libxcursor1 \
    libxinerama1 \
    libxrandr2 \
    libxrender1 \
    libgl1-mesa-glx \
    libxi6 \
    libasound2 \
    libpulse0 \
    libdbus-1-3 \
    && rm -rf /var/lib/apt/lists/*

# Descargar Godot 4.3 estable (Versión oficial)
RUN wget -q https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip \
    && unzip Godot_v4.3-stable_linux.x86_64.zip \
    && mv Godot_v4.3-stable_linux.x86_64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm Godot_v4.3-stable_linux.x86_64.zip

WORKDIR /app

# Copiamos todo el proyecto
COPY . .

# Pre-importar recursos
RUN godot --headless --import || true

# Comando para arrancar el servidor
CMD ["godot", "--headless", "--path", "/app"]