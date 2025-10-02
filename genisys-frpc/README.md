# Genisys FRPC (Home Assistant add-on)

Espone Home Assistant su Internet tramite FRP (reverse proxy) usando un **token condiviso**.

## Configurazione

- **frp_server_addr**: `api.genisysdomotica.it`
- **frp_server_port**: `7000`
- **frp_shared_token**: **obbligatorio** (lo trovi nel pannello *Genisys Admin* accanto al cliente)
- **local_ip** / **local_port**: Home Assistant locale (di default `homeassistant:8123`)
- **custom_domain** (consigliato): es. `ha-mario.genisysdomotica.it`
- **subdomain** (alternativa): es. `ha-mario` (usato solo se `custom_domain` è vuoto)

> Nota: `custom_domain` ha la precedenza su `subdomain`.

## Requisiti lato server

- Il dominio pubblico deve esistere e puntare al reverse proxy (Caddy) che inoltra al tuo FRP server.
- FRP server (`frps`) deve avere lo **stesso token** configurato.

