# La Carreta - App Móvil

Aplicación móvil de uso interno para el personal de **La Carreta**. 
Permite la gestión de inventarios, levantamiento de pedidos, visualización de rutas asignadas y control general de operaciones en tiempo real.

## Requisitos Previos

- Flutter SDK (versión más reciente)
- Dispositivo físico o emulador configurado

## Configuración del Proyecto

1. Instala las dependencias de Flutter:
   ```bash
   flutter pub get
   ```

2. Configura las variables de entorno:
   - Haz una copia del archivo `env.json.template` y nómbralo `env.json`.
   - Modifica el archivo `env.json` con la URL base de tu backend (`API_URL`).

3. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

## Estructura del Proyecto

El proyecto sigue una arquitectura limpia (Clean Architecture) orientada a características (Feature-first), utilizando **Cubit (Bloc)** para la gestión de estados.

- `/lib/core`: Componentes base (red, base de datos local, temas, router, widgets genéricos).
- `/lib/features`: Módulos principales (Autenticación, Pedidos, etc.).
