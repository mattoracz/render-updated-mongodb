FROM mongodb/mongodb-community-server:8.0-ubuntu2204

RUN mkdir -p /var/log/mongodb && chown mongodb:mongodb /var/log/mongodb

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
