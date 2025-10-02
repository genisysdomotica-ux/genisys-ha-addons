#!/usr/bin/env bash
set -euo pipefail

# Legge opzioni dall’add-on
FRP_ADDR="$(bashio::config 'frp_server_addr')"
FRP_PORT="$(bashio::config 'frp_server_port')"
FRP_TOKEN="$(bashio::config 'frp_shared_token')"

LOCAL_IP="$(bashio::config 'local_ip')"
LOCAL_PORT="$(bashio::config 'local_port')"
SUBDOMAIN="$(bashio::config 'subdomain')"
CUSTOM_DOMAIN="$(bashio::config 'custom_domain')"

bashio::log.info "Avvio Genisys FRPC add-on"
bashio::log.info "Scarico frpc ${FRP_VERSION:-0.64.0}..."

ARCH="$(uname -m)"
URL_BASE="https://github.com/fatedier/frp/releases/download/v${FRP_VERSION:-0.64.0}"
case "$ARCH" in
  x86_64)   PKG="frp_${FRP_VERSION:-0.64.0}_linux_amd64.tar.gz" ;;
  aarch64)  PKG="frp_${FRP_VERSION:-0.64.0}_linux_arm64.tar.gz" ;;
  armv7l)   PKG="frp_${FRP_VERSION:-0.64.0}_linux_arm.tar.gz" ;;
  armv6l)   PKG="frp_${FRP_VERSION:-0.64.0}_linux_arm.tar.gz" ;;
  i686)     PKG="frp_${FRP_VERSION:-0.64.0}_linux_386.tar.gz" ;;
  *)        bashio::log.fatal "Arch non supportata: $ARCH" ;;
esac

TMP=/tmp/frp
mkdir -p "$TMP"
curl -fsSL -o "$TMP/frpc.tgz" "${URL_BASE}/${PKG}"
tar -C "$TMP" -xzf "$TMP/frpc.tgz"
FRPDIR="$(find "$TMP" -maxdepth 1 -type d -name 'frp_*' | head -n1)"
install -m0755 "$FRPDIR/frpc" /usr/local/bin/frpc

# Crea frpc.ini
CONF=/data/frpc.ini
{
  echo "[common]"
  echo "server_addr = ${FRP_ADDR}"
  echo "server_port = ${FRP_PORT}"
  echo "token = ${FRP_TOKEN}"
  echo
  echo "[homeassistant]"
  echo "type = http"
  echo "local_ip = ${LOCAL_IP}"
  echo "local_port = ${LOCAL_PORT}"
  if [[ -n "${SUBDOMAIN}" ]]; then
    echo "subdomain = ${SUBDOMAIN}"
  fi
  if [[ -n "${CUSTOM_DOMAIN}" ]]; then
    echo "custom_domains = ${CUSTOM_DOMAIN}"
  fi
} > "$CONF"

bashio::log.info "Configurazione FRPC:"
cat "$CONF" | sed -E 's/(token = ).+/\1****/'

# Avvia FRPC
exec frpc -c "$CONF"

fi

# Mappa architettura
ARCH="$(apk --print-arch || true)"
case "$ARCH" in
  x86_64)   FRP_ARCH="amd64" ;;
  aarch64)  FRP_ARCH="arm64" ;;
  armv7|armhf) FRP_ARCH="arm" ;;
  i386|x86) FRP_ARCH="386" ;;
  *) echo "[ERROR] Architettura non supportata: $ARCH"; exit 1 ;;
esac

# Scarico frpc se assente
mkdir -p /opt/frp /data
cd /opt/frp
if [[ ! -x ./frpc ]]; then
  URL="https://github.com/fatedier/frp/releases/download/v${FRPC_VERSION}/frp_${FRPC_VERSION}_linux_${FRP_ARCH}.tar.gz"
  echo "[INFO] Scarico frpc ${FRPC_VERSION} (${FRP_ARCH})..."
  curl -fsSL "$URL" -o frp.tgz
  tar -xzf frp.tgz --strip-components=1 "frp_${FRPC_VERSION}_linux_${FRP_ARCH}/frpc"
  rm -f frp.tgz
  chmod +x frpc
fi

# Genero configurazione INI
CFG="/data/frpc.ini"
cat > "$CFG" <<EOF
[common]
server_addr = ${FRP_SERVER_ADDR}
server_port = ${FRP_SERVER_PORT}
token = ${FRP_SHARED_TOKEN}

[homeassistant]
type = http
local_ip = ${LOCAL_IP}
local_port = ${LOCAL_PORT}
EOF

if [[ -n "$CUSTOM_DOMAIN" ]]; then
  echo "custom_domains = ${CUSTOM_DOMAIN}" >> "$CFG"
elif [[ -n "$SUBDOMAIN" ]]; then
  echo "subdomain = ${SUBDOMAIN}" >> "$CFG"
fi

echo "[INFO] Configurazione FRPC:"
sed -e "s/${FRP_SHARED_TOKEN:0:4}.*/****/" "$CFG"

echo "[INFO] Avvio frpc..."
exec /opt/frp/frpc -c "$CFG"

