# PIE — Módulo de medición 3D con Intel RealSense D435i

Pipeline en MATLAB para capturar y medir palets mediante cámara de profundidad,
desarrollado como parte de la asignatura INT (ETSETB–UPC, curso 2024/25).

El objetivo del proyecto era detectar defectos en palets (medidas incorrectas,
tablas faltantes) dentro de un Product Inspection Entry automatizado, usando
cámaras 3D en lugar de inspección manual.

![Pipeline](img/pipeline.svg)

## Enfoque

El equipo evaluó **cuatro aproximaciones** en paralelo para no quedar atado a una
sola solución antes de invertir en una cámara cara: medición lateral, desde abajo,
con perspectiva, y mediante nube de puntos 3D.

Este repositorio corresponde al **cuarto enfoque: comprobación de integridad del
palet mediante mapa de puntos 3D**, usando una Intel RealSense D435i (una cámara
3D de gama baja, elegida por restricciones de presupuesto) para detectar grietas
y tablas faltantes.

## Mi aportación

Este repositorio contiene **únicamente la parte que desarrollé yo**: la captura
de profundidad y el pipeline de medición sobre nube de puntos. El proyecto
completo fue un trabajo de grupo y está disponible en
[mahelbdlm/INT](https://github.com/mahelbdlm/INT).

## Resultados

El palet físico utilizado en el prototipo, con tablas desgastadas y huecos
irregulares:

![Palet real](img/palet_real.jpg)

Reconstrucción en nube de puntos a partir del mapa de profundidad de la D435i.
Se distingue la estructura de tablas y los huecos entre ellas:

![Nube de puntos](img/nube_puntos.png)

Vista en perspectiva de la misma captura, coloreada por altura:

![Nube de puntos en perspectiva](img/nube_puntos_perspectiva.png)

Vista cenital de la nube de puntos durante una inspección:

![Vista cenital de la nube de puntos](img/deteccion_defectos.png)

## Cómo se detectan los defectos

El módulo no clasifica defectos directamente: mide el palet y lo compara contra
una referencia. Tres mecanismos encadenados.

### 1. Segmentación por umbral de profundidad

El mapa de profundidad llega en milímetros y se convierte a metros. El palet se
aísla del fondo y del suelo quedándose solo con los píxeles dentro de una banda
de distancia conocida:

```matlab
min_dist = 0.1;   % metros
max_dist = 0.75;
palet_mask = (depth >= min_dist) & (depth <= max_dist);
```

La banda depende de la altura a la que esté montada la cámara en el prototipo.
Todo lo que cae fuera (suelo, estructura, cinta) se descarta antes de medir.

### 2. Comparación por correlación de Pearson

Se capturan dos escaneos y se comparan píxel a píxel sobre la profundidad
segmentada, calculando el coeficiente de correlación de Pearson entre ambos
vectores y expresándolo en porcentaje.

La idea: un palet íntegro comparado con la referencia da una correlación alta.
Una tabla rota, un hueco o una grieta cambian la geometría local y hacen caer
ese porcentaje. Sirve como indicador de desviación, no como localizador del
defecto concreto.

### 3. Medición de dimensiones

Dos caminos independientes, para contrastar resultados:

**Vía profundidad** (`mesure_depth_solution.m`) — sobre un ROI seleccionado, el
tamaño de píxel se deriva del campo de visión de la D435i (87° × 58°) y la
resolución de captura:

```matlab
pixelSizeX = (2 * tan(deg2rad(87/2)) / 640) * 1000;   % mm/píxel
```

Con eso se obtienen ancho y alto en milímetros, más la profundidad media del
ROI. Las medidas se contrastan contra las normalizadas: 80 cm de ancho el palet
europeo, 100 cm el americano.

**Vía RGB** (`mesures_rgb.m`) — se restan dos frames consecutivos en escala de
grises y se umbraliza la diferencia para aislar lo que se ha movido:

```matlab
diff_image  = abs(double(gray1) - double(gray2));
motion_mask = diff_image > 30;
```

La máscara se limpia con apertura y cierre morfológicos (elemento estructurante
circular de radio 5), se detectan bordes con Canny, y de las regiones conectadas
se toma la de mayor área. Su bounding box da las dimensiones del palet.

## Limitaciones conocidas

- La correlación detecta que algo se desvía, pero no dónde ni de qué tipo.
- La conversión de píxeles a metros en la vía RGB usa un factor fijo calibrado
  para una distancia concreta; cambiar la altura de la cámara lo invalida.
- El cálculo de tamaño de píxel vía FOV asume un plano a profundidad constante.
- `mesure_depth_solution.m` requiere seleccionar el ROI a mano.
- Los scripts parten de capturas `.mat`; una versión de producción leería los
  frames directamente de la cámara.

## Estructura

| Fichero | Qué hace |
|---|---|
| `connectDepth.m` | Configura el pipeline de la D435i (resolución y fps parametrizables) |
| `depthCapture.m` | Captura de frames de profundidad |
| `scan2images.m` | Conversión del escaneo a secuencia de imágenes |
| `scan2mascara.m` | Aísla el palet por umbral de distancia y genera la máscara |
| `mesures_rgb.m` | Medición sobre canal RGB, con detección de movimiento entre frames |
| `mesure_depth_solution.m` | Medición sobre mapa de profundidad vía Image Acquisition Toolbox |
| `video_mesura.m` | Medición sobre secuencias de vídeo |
| `janvideo.m` | Utilidad de reproducción de capturas |
| `prueba1.m` | Script de pruebas del pipeline |
| `indent.m` | Utilidad auxiliar |

## Requisitos

- MATLAB (probado con R2024a)
- Image Processing Toolbox / Computer Vision Toolbox
- Intel RealSense D435i + SDK

## Contexto

Desarrollado entre octubre y diciembre de 2024. El historial original de estos
commits está en el repositorio del grupo enlazado arriba.
