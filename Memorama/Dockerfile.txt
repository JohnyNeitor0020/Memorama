# Usamos una imagen base ligera de Ubuntu
FROM ubuntu:22.04

# Instalamos las librerías mínimas que Godot necesita para correr en Linux
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libfontconfig1 \
    libxcursor1 \
    libxinerama1 \
    libxrandr2 \
    librender9 \
    && rm -rf /var/lib/apt/lists/*

# Creamos el directorio de la app
WORKDIR /app

# Copiamos todos los archivos de tu carpeta local al contenedor
COPY . .

# Le damos permisos de ejecución al binario de Godot
RUN chmod +x server.x86_64

# Exponemos el puerto (Render usará el que le asigne la variable PORT)
EXPOSE 10000

# Comando para arrancar el servidor en modo "sin ventana"
CMD ["./server.x86_64", "--headless"]