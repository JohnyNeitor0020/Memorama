# Usamos una imagen base ligera de Ubuntu
FROM ubuntu:22.04

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Instalamos las librerías necesarias para Godot 4
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libfontconfig1 \
    libxcursor1 \
    libxinerama1 \
    libxrandr2 \
    libxrender1 \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

# Creamos el directorio de la app
WORKDIR /app

# Copiamos todo el contenido de la carpeta Memorama
COPY . .

# Damos permisos de ejecución al binario
RUN chmod +x server.x86_64

# Comando para arrancar el servidor
CMD ["./server.x86_64", "--headless"]