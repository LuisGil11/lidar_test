# LiDAR Tennis Ball Test App

App simple para probar el sensor LiDAR del iPhone con pelota de tenis.

## Instalacion

1. Abre `LiDARTennisTest.xcodeproj` en Xcode (en tu VM de macOS)

2. Conecta tu iPhone 15 Pro Max al Mac

3. Selecciona tu iPhone como destino en Xcode

4. En Xcode, ve a "Signing & Capabilities":
   - Selecciona tu Team (Apple ID)
   - Cambia el Bundle Identifier si es necesario

5. Build and Run (Cmd + R)

## Como Usar

1. Apunta el iPhone hacia una pelota de tenis

2. Usa la cruz verde en el centro para apuntar a la pelota

3. La app mostrara:
   - Distancia al centro (metros)
   - Numero de puntos LiDAR detectados
   - Confianza de la medicion
   - Si detecta la pelota (verde)
   - Posicion 3D (X, Y, Z)

## Pruebas Recomendadas

Prueba la pelota a diferentes distancias:

- 0.5m - Muy cerca
- 1.0m - Cerca
- 2.0m - Distancia media
- 3.0m - Distancia normal
- 4.0m - Lejos
- 5.0m - Limite del LiDAR

Anota en cual distancia deja de detectar la pelota claramente.

## Que Esperar

LiDAR funciona mejor con:
- Objetos grandes (>10cm)
- Superficies no reflectivas
- Buena iluminacion

La pelota de tenis (6.7cm) esta en el limite de deteccion.

## Limitaciones

- Rango maximo: 5 metros
- Frecuencia: ~10-15 Hz (no 30-60 fps)
- Objetos pequenos son dificiles de detectar
- Motion blur afecta la deteccion
