#!/usr/bin/env python3
"""Helper para el plasmoide de conexiones de red."""

from __future__ import annotations

import argparse
import json
import os
import re
import socket
import subprocess
from datetime import datetime, timezone

import ipaddress
import psutil
import requests


def is_private_or_local_ip(ip: str) -> bool:
    try:
        ip_obj = ipaddress.ip_address(ip)
        return (
            ip_obj.is_private
            or ip_obj.is_loopback
            or ip_obj.is_link_local
            or ip_obj.is_reserved
            or ip_obj.is_multicast
        )
    except ValueError:
        return True


def get_process_details(pid: int | None) -> dict:
    if not pid:
        return {"name": "unknown", "command": "unknown"}

    try:
        process = psutil.Process(pid)
        command = " ".join(process.cmdline()).strip() or process.name()
        return {"name": process.name(), "command": command}
    except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
        return {"name": "unknown", "command": "unknown"}
    except Exception:
        return {"name": "unknown", "command": "unknown"}


def lookup_company_and_country(ip: str, cache: dict[str, dict]) -> dict:
    if ip in cache:
        return cache[ip]

    info = {"company": "unknown", "country": "unknown", "source": "whois"}

    if is_private_or_local_ip(ip):
        info.update({"company": "local/private", "country": "local", "source": "local"})
        cache[ip] = info
        return info

    whois_output = ""
    try:
        result = subprocess.run(["whois", ip], capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            whois_output = result.stdout or ""
    except FileNotFoundError:
        pass
    except subprocess.TimeoutExpired:
        pass
    except Exception:
        pass

    if whois_output:
        for pattern in [r"(?im)^(org-name|organization|org|netname|descr|owner):\s*(.+)$"]:
            match = re.search(pattern, whois_output)
            if match:
                candidate = match.group(2).strip()
                if candidate:
                    info["company"] = candidate
                    break

        country_match = re.search(r"(?im)^(country|registrant country):\s*(.+)$", whois_output)
        if country_match:
            info["country"] = country_match.group(2).strip()

    if info["company"] == "unknown" or info["country"] == "unknown":
        try:
            geo = requests.get(
                f"http://ip-api.com/json/{ip}?fields=status,message,country,isp,org,query",
                timeout=5,
            ).json()
            if isinstance(geo, dict):
                info["company"] = geo.get("org") or geo.get("isp") or info["company"]
                info["country"] = geo.get("country") or info["country"]
                info["source"] = geo.get("status") or info["source"]
        except Exception:
            pass

    cache[ip] = info
    return info


def build_network_connections_table() -> dict:
    connections = []
    whois_cache: dict[str, dict] = {}

    for conn in psutil.net_connections(kind="inet"):
        if not conn.raddr:
            continue

        local_ip = conn.laddr.ip if conn.laddr else "0.0.0.0"
        local_port = conn.laddr.port if conn.laddr else 0
        remote_ip = conn.raddr.ip
        remote_port = conn.raddr.port

        process_info = get_process_details(conn.pid)
        remote_info = lookup_company_and_country(remote_ip, whois_cache)
        local_country = "local" if is_private_or_local_ip(local_ip) else "unknown"

        connections.append(
            {
                "ip_origen": local_ip,
                "ip_destino": remote_ip,
                "puerto_origen": local_port,
                "puerto": remote_port,
                "empresa": remote_info.get("company", "unknown"),
                "pais_origen": local_country,
                "pais_destino": remote_info.get("country", "unknown"),
                "pais": remote_info.get("country", "unknown"),
                "proceso": process_info.get("name", "unknown"),
                "proceso_comando": process_info.get("command", "unknown"),
                "pid": conn.pid,
                "estado": conn.status,
            }
        )

    connections.sort(key=lambda row: (row["ip_destino"], row["puerto"], row["proceso"]))

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "total_connections": len(connections),
        "connections": connections,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Genera JSON con conexiones de red para el plasmoide")
    parser.add_argument("--nonce", help="Valor opaco para forzar una nueva ejecución", default="")
    args = parser.parse_args()

    payload = build_network_connections_table()
    print(json.dumps(payload, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
