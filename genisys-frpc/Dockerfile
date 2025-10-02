ARG BUILD_FROM
FROM $BUILD_FROM

# (Le base image HA includono s6 & bashio; teniamo l'immagine pulita)
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copia lo start script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Avvio
CMD [ "/run.sh" ]

