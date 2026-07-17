#!/bin/bash

# Script para compilar la aplicación La Carreta en producción optimizada.
# Este script realiza la limpieza, ofuscación y compresión del APK para mayor seguridad y ligereza.

if [ ! -f "env.json" ]; then
  echo "⚠️  ERROR: No se encontró el archivo env.json en la raíz del proyecto."
  echo "Creando un archivo env.json de ejemplo..."
  echo '{"API_URL": "http://TU_IP_SERVIDOR:3000/api"}' > env.json
  echo "Por favor edita env.json con la URL real de tu servidor antes de compilar."
  exit 1
fi

echo "🧹 Limpiando proyecto..."
flutter clean

echo "📦 Obteniendo dependencias..."
flutter pub get

echo "🚀 Compilando APK optimizado..."
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --dart-define-from-file=env.json

echo "✅ Compilación completada con éxito."
echo "📍 APK generado en: build/app/outputs/flutter-apk/app-release.apk"
echo "📍 Símbolos de depuración en: build/app/outputs/symbols"
