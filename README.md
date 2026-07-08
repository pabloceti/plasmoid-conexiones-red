# plasmoid-conexiones-red

Plasmoide para KDE Plasma que muestra conexiones de red activas en una tabla ordenable.

## Características

- Icono en el panel de KDE.
- Tabla con IP origen, IP destino, puerto, empresa, país y proceso.
- Ordenación por columnas.
- Instalador local con `install.sh`.
- Backend autónomo, sin depender de `agenteLinux.py`.

## Requisitos

- KDE Plasma.
- Python 3.
- `psutil`
- `requests`
- `whois`

## Instalación

```bash
chmod +x install.sh
./install.sh
```

Para probar sin instalar:

```bash
./install.sh --dry-run
```

## Estructura

- `metadata.json`
- `contents/ui/main.qml`
- `contents/scripts/network_table.py`
- `install.sh`
- `MANUAL-INSTALACION.md`

## Licencia

GPL-3.0-or-later
