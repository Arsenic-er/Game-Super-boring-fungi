[English](README.en.md) | [简体中文](README.zh-Hans.md) | [繁體中文](README.zh-Hant.md) | [日本語](README.ja.md) | [**Español**](README.es.md) | [Deutsch](README.de.md) | [Русский](README.ru.md)

# Game: Super boring fungi

Un juego incremental de evolución y expansión que comienza con una espora microscópica y crece hasta alcanzar ecosistemas, sociedades humanas, países y, finalmente, todo el planeta.

El proyecto se encuentra en la fase de prototipo temprano para Windows, versión `0.45.0`. El desarrollo actual se centra en el Capítulo 1, un microcultivo de laboratorio visto desde arriba en el que el jugador controla exclusivamente al hongo, extiende su red de hifas, absorbe nutrientes, evoluciona nuevas capacidades y dirige esporas expedicionarias. La versión 0.40 incorpora órdenes seguras según la función de cada unidad, evitando que una espora recolecte o ataque objetivos incompatibles con su especialización.

La v0.41 muestra la selección de siete idiomas al iniciar por primera vez una instalación nueva y ofrece chino simplificado, chino tradicional, inglés, japonés, español, alemán y ruso para el HUD de recursos, las acciones radiales del núcleo, el estado del núcleo y las ayudas emergentes habituales, el estado de las expediciones, las descripciones de las bacterias y los nombres de las diez clases de unidad; la tienda de mejoras y el texto completo de los objetivos a largo plazo aún no están totalmente traducidos.

La v0.42 traduce a los siete idiomas los 22 objetivos a largo plazo, el marco de la tienda de evolución, las mejoras de nodo y supervivencia, las mejoras estructurales, la página de unidades generales del cuartel, la mitad inferior del panel de estado del cuartel y los detalles de tres unidades especiales. Siguen pendientes las páginas de detalle de dietas, los componentes bacterianos, las páginas de unidades exclusivas de cada dieta, los avisos de compra e interacción del cuartel y los textos de guía del capítulo, eventos ecológicos y lluvia de esporas rival.

La v0.43 añade al menú de pausa de Esc una guía ilustrada de seis páginas. Explica germinación, nutrientes y ADN, evolución, órdenes del cuartel, exploración y objetivos, y supervivencia de la colonia en los siete idiomas, con una imagen de píxeles gruesos para cada tema.
La v0.44 completa en siete idiomas las páginas de dietas, componentes bacterianos y unidades especializadas, y traduce las compras, desbloqueos y avisos de error de evolución. Las etiquetas largas se ajustan ahora dentro de la interfaz de píxeles.
La v0.45 traduce a siete idiomas la guía del Capítulo 1, los eventos ecológicos, las fases y recompensas de la lluvia rival, las alertas enemigas y las unidades de tiempo. Los avisos largos se ajustan a pantallas estrechas.

## Descarga y ejecución

Abre la [versión más reciente](https://github.com/Arsenic-er/Game-Super-boring-fungi/releases/latest) del repositorio, descarga el ZIP para Windows, extráelo y ejecuta `FungiMicroculture.exe`.

- Plataforma: Windows 10/11 de 64 bits
- Instalación: no es necesaria; todos los datos del juego están integrados en el EXE
- Partidas guardadas: se almacenan en la carpeta de datos de aplicación del usuario actual de Windows
- Windows puede mostrar una advertencia de SmartScreen porque esta compilación experimental no está firmada digitalmente

## Características principales

- Explora un amplio entorno de laboratorio con zoom, nutrientes orgánicos agrupados, iones minerales, colonias bacterianas, hongos rivales y niebla de guerra permanente.
- Germina desde un único núcleo de espora, extiende hifas principales y desarrolla finas hifas absorbentes que acumulan recursos lentamente con precisión decimal.
- Consume nutrientes para producir ADN, adquirir evoluciones reversibles, mejorar estructuras, supervivencia, adaptación y dietas, y completar objetivos a largo plazo con distintas recompensas.
- Gestiona la biomasa con tres decimales de núcleos y esporas, el daño por toxinas, la recuperación gradual, la retirada para reparaciones y la muerte o reconexión de hifas aisladas.
- Construye núcleos de cuartel y produce esporas especializadas en recolección, transporte, minerales, exploración, combate antibacteriano, combate antifúngico y despliegue de zonas.
- Asigna zonas cuadradas persistentes de defensa, recolección o purga bacteriana; las unidades compatibles reanudan su misión después de descargar, repararse, ser reemplazadas o avanzar sin conexión.
- Las órdenes seguras de v0.40 permiten atacar o recolectar únicamente a las funciones compatibles. Las unidades incompatibles de un grupo mixto avanzan hasta la zona y mantienen la posición; el recibo de la orden muestra cuántas ejecutan, vigilan o no están disponibles.
- Afronta proliferaciones bacterianas, zonas tóxicas, lluvias de esporas rivales, anomalías de recursos, exploración bajo niebla, progreso incremental y un paisaje sonoro original de laboratorio pixelado con canales ajustables.

## Resumen de controles

- ADN del núcleo: clic normal para producir 1; Shift + clic para 5; Ctrl + clic para 10
- Clic izquierdo: inspeccionar núcleos, elegir acciones o seleccionar esporas expedicionarias
- Arrastrar con el botón izquierdo: seleccionar unidades mediante un rectángulo
- Clic derecho: ordenar movimiento, recolección, ataque, corte de hifas o despliegue
- `Z`: definir una zona cuadrada de defensa
- `X`: definir una zona cuadrada de recolección
- `V`: definir una zona cuadrada de purga bacteriana
- `C`: cancelar las órdenes manuales o persistentes y devolver las unidades sanas a su comportamiento automático según su función
- `R`: hacer regresar las esporas seleccionadas a su cuartel
- Arrastrar con el botón derecho o central: mover la cámara
- Rueda del ratón: acercar o alejar
- `E`: abrir la tienda de evolución
- `G`: abrir los objetivos a largo plazo
- `F5`: guardar inmediatamente
- `Esc`: cerrar un panel, cancelar una acción o pausar/reanudar

## Progresión de escalas prevista

El microcultivo es solo el punto de partida. Los futuros capítulos independientes avanzarán por microorganismos y células, pequeños organismos y objetos, ecosistemas, sociedad humana, ciudades, países y la Tierra moderna. Los rasgos fisiológicos evolucionados en escalas anteriores influirán en las estrategias posteriores de propagación y conquista.

## Desarrollo

El proyecto utiliza Godot `4.7` y GDScript. Abre `project.godot` con Godot para ejecutar el código fuente. Las pruebas automatizadas se encuentran en `tests/`, y la configuración de exportación para Windows integra los datos del juego en un único EXE.

## Derechos

Copyright © 2026 koko. Todos los derechos reservados.

El código fuente, los recursos visuales y sonoros, el diseño, los textos y los demás contenidos del repositorio son públicos únicamente para su consulta y evaluación. **No se autoriza su copia, reutilización, modificación, redistribución, uso en obras derivadas ni explotación comercial**. La compilación oficial solo puede descargarse y ejecutarse para uso personal y evaluación. Consulta [LICENSE](../../LICENSE).
