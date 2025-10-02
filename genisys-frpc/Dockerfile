# Base ufficiale per add-on Home Assistant (include s6-overlay e bashio)
FROM ghcr.io/hassio-addons/base:16.1.1

# Facoltativo ma utile per debug
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copia lo script di avvio
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Avvia lo script (lo shebang userà with-contenv+bashio)
CMD [ "/run.sh" ]
