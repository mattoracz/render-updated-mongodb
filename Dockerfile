FROM mongodb/mongodb-community-server:8.0-ubuntu2204

USER root
RUN mkdir -p /var/log/mongodb && chown mongodb:mongodb /var/log/mongodb
COPY --chmod=755 entrypoint.sh /entrypoint.sh
USER mongodb

ENTRYPOINT ["/entrypoint.sh"]
