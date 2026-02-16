FROM mongodb/mongodb-community-server:8.0-ubuntu2204

USER root
RUN apt-get update && apt-get install -y gosu && rm -rf /var/lib/apt/lists/*
COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
