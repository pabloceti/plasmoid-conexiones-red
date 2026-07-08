# Manual de instalación del plasmoide de conexiones de red

Este plasmoide muestra una tabla con conexiones de red activas y permite ordenarlas por columnas. El paquete es independiente y no necesita `agenteLinux.py` para funcionar.

## Requisitos

- KDE Plasma con soporte para plasmoides de tipo declarative applet.
- Python 3.
- Paquetes de Python disponibles en el sistema:
  - `psutil`
  - `requests`
- El comando `whois` instalado para mejorar la detección de empresa asociada a la IP.

## Estructura del plasmoide

La carpeta del plasmoide es:

`plasmoid-conexiones-red/`

Contiene:

- `metadata.json`
- `contents/ui/main.qml`
- `contents/scripts/network_table.py`

## Instalación manual

1. Copia la carpeta `plasmoid-conexiones-red` al directorio de plasmoides del usuario:

   `~/.local/share/plasma/plasmoids/`

   El resultado debe quedar así:

   `~/.local/share/plasma/plasmoids/plasmoid-conexiones-red/`

2. Asegúrate de que el script auxiliar tenga permisos de ejecución:

   `chmod +x ~/.local/share/plasma/plasmoids/plasmoid-conexiones-red/contents/scripts/network_table.py`

3. Reinicia Plasma o recarga el shell para que detecte el nuevo plasmoide.

   Puedes usar uno de estos métodos:

   - Cerrar sesión y volver a entrar.
   - Ejecutar `kquitapp5 plasmashell && kstart5 plasmashell`.
   - En algunas versiones, usar `plasma-discover` no es necesario; el plasmoide se carga localmente.

4. Añade el plasmoide al panel:

   - Clic derecho sobre el panel.
   - Selecciona `Entrar en modo edición`.
   - Elige `Añadir widgets`.
   - Busca `Conexiones de Red`.
   - Arrástralo al panel.

## Instalación automática

Desde la carpeta `plasmoid-conexiones-red/`, ejecuta:

`./install.sh`

El script copia el plasmoide a la ruta local de Plasma y, si es posible, reinicia `plasmashell` para que aparezca de inmediato. Si quieres probar sin instalar, usa:

`./install.sh --dry-run`

Si no quieres que intente reiniciar Plasma, usa:

`./install.sh --no-reload`

## Instalación desde el editor

Si estás trabajando desde VS Code, puedes copiar la carpeta completa a:

`~/.local/share/plasma/plasmoids/`

Luego reinicia Plasma o vuelve a iniciar sesión.

## Uso

- El icono del plasmoide abre la vista con la tabla.
- El botón `Refrescar` vuelve a consultar las conexiones actuales.
- Los encabezados de la tabla son clicables y permiten ordenar por:
  - IP origen
  - IP destino
  - Puerto
  - Empresa
  - País origen
  - País destino
  - Proceso

## Desinstalación

1. Quita el plasmoide del panel.
2. Borra la carpeta:

   `~/.local/share/plasma/plasmoids/plasmoid-conexiones-red/`

3. Reinicia Plasma si el widget sigue apareciendo en el catálogo.

## Solución de problemas

### No aparece el plasmoide en el panel

- Verifica que la ruta sea exactamente `~/.local/share/plasma/plasmoids/plasmoid-conexiones-red/`.
- Comprueba que existe `metadata.json` en la raíz del paquete.
- Reinicia la sesión de Plasma.

### La tabla aparece vacía

- Comprueba que el sistema tenga conexiones activas en ese momento.
- Verifica que Python 3 puede importar `psutil` y `requests`.
- Si `whois` no está instalado, la tabla seguirá funcionando, pero la columna de empresa puede mostrar valores genéricos.

### No se puede ejecutar el helper

- Revisa permisos del archivo:

  `chmod +x ~/.local/share/plasma/plasmoids/plasmoid-conexiones-red/contents/scripts/network_table.py`

- Prueba el backend manualmente:

  `python3 ~/.local/share/plasma/plasmoids/plasmoid-conexiones-red/contents/scripts/network_table.py`

### La ordenación no cambia

- Haz clic sobre el encabezado de la columna.
- El primer clic ordena ascendente y el segundo descendente.

## Nota técnica

Este plasmoide ya no depende de `agenteLinux.py`. Si quieres volver a integrarlo con el agente en el futuro, puedes hacerlo sin cambiar la interfaz del widget.
