#!/usr/bin/with-contenv bashio
set -euo pipefail

bashio::log.info "Avvio Genisys FRPC add-on"

# --- Leggo configurazione dall’UI dell’add-on ---
FRP_SERVER_ADDR=$(bashio::config 'frp_server_addr')
FRP_SERVER_PORT=$(bashio::config 'frp_server_port')
FRP_SHARED_TOKEN=$(bashio::config 'frp_shared_token')
LOCAL_IP=$(bashio::config 'local_ip')
LOCAL_PORT=$(bashio::config 'local_port')
SUBDOMAIN=$(bashio::config 'subdomain')
CUSTOM_DOMAIN=$(bashio::config 'custom_domain')

# --- Validazioni minime ---
if [[ -z "${FRP_SERVER_ADDR}" || -z "${FRP_SHARED_TOKEN}" ]]; then
  bashio::log.fatal "frp_server_addr e frp_shared_token sono obbligatori"
  exit 1
fi

# --- Scarico frpc se non presente ---
ARCH="$(bashio::info.arch)"
# Mappatura arch -> nome frp binario
case "$ARCH" in
  aarch64)  FRP_ARCH="linux_arm64" ;;
  armv7)    FRP_ARCH="linux_arm" ;;
  armhf)    FRP_ARCH="linux_arm" ;;
  i386)     FRP_ARCH="linux_386" ;;
  amd64)    FRP_ARCH="linux_amd64" ;;
  *)        bashio::log.fatal "Architettura non supportata: $ARCH"; exit 1 ;;
esac

FRP_VERSION="0.64.0"
FRP_TGZ="frp_${FRP_VERSION}_${FRP_ARCH}.tar.gz"
FRP_URL="https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FRP_TGZ}"

if [[ ! -x /data/frpc ]]; then
  bashio::log.info "Scarico frpc ${FRP_VERSION} (${FRP_ARCH})..."
  TMPDIR=$(mktemp -d)
  curl -fsSL -o "${TMPDIR}/${FRP_TGZ}" "${FRP_URL}"
  tar -xzf "${TMPDIR}/${FRP_TGZ}" -C "${TMPDIR}"
  cp "${TMPDIR}/frp_${FRP_VERSION}_${FRP_ARCH}/frpc" /data/frpc
  chmod +x /data/frpc
  rm -rf "${TMPDIR}"
fi

# --- Genero configurazione INI per frpc ---
bashio::log.info "Configuro FRPC..."
cat > /data/frpc.ini <<EOF
[common]
server_addr = ${FRP_SERVER_ADDR}
server_port = ${FRP_SERVER_PORT}
token = ${FRP_SHARED_TOKEN}

[homeassistant]
type = http
local_ip = ${LOCAL_IP}
local_port = ${LOCAL_PORT}
EOF

# Se c'è custom_domain uso quello, altrimenti subdomain
if [[ -n "${CUSTOM_DOMAIN}" ]]; then
  echo "custom_domains = ${CUSTOM_DOMAIN}" >> /data/frpc.ini
else
  # Nota: solo la parte prima del dominio; es: ha-mario
  if [[ -n "${SUBDOMAIN}" ]]; then
    echo "subdomain = ${SUBDOMAIN}" >> /data/frpc.ini
  fi
fi

bashio::log.info "Configurazione FRPC:"
sed 's/token = .*/token = ****/g' /data/frpc.ini | sed 's/^/  /'

# --- Avvio frpc ---
bashio::log.info "Avvio frpc..."
exec /data/frpc -c /data/frpc.ini

