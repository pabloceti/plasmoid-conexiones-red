# plasmoid-conexiones-red

Plasmoide para KDE Plasma 6 que muestra conexiones de red activas en una tabla ordenable.

## Características

- Icono en el panel de KDE.
- Tabla con IP origen, IP destino, puerto, empresa, país y proceso.
- Ordenación por columnas (ascendente y descendente).
- Columnas alineadas con anchos consistentes para una lectura clara.
- Actualización automática cada 20 segundos por defecto.
- Intervalo de actualización configurable desde el panel de configuración del widget.
- Instalador local con `install.sh`.
- Backend autónomo, sin depender de `agenteLinux.py`.

## Requisitos

- KDE Plasma 6.
- Python 3.
- `psutil`
- `requests`
- `whois`
- Módulo QML `org.kde.plasma.plasma5support` (paquete `plasma5support` en Arch/Garuda).

## Instalación

```bash
chmod +x install.sh
./install.sh
```

Para probar sin instalar:

```bash
./install.sh --dry-run
```

## Configuración

1. Clic derecho sobre el widget en Plasma.
2. Selecciona **Configurar elemento gráfico**.
3. En **General**:
	- Activa o desactiva la actualización automática.
	- Ajusta el intervalo de actualización en segundos (mínimo 5).

## Estructura

- `metadata.json`
- `contents/config/main.xml`
- `contents/config/config.qml`
- `contents/ui/main.qml`
- `contents/ui/config/ConfigGeneral.qml`
- `contents/scripts/network_table.py`
- `install.sh`
- `MANUAL-INSTALACION.md`

## Licencia

GPL-3.0-or-later
