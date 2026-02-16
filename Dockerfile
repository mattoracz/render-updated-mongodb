FROM mongo:8.0

COPY init-user.sh /docker-entrypoint-initdb.d/init-user.sh
RUN chmod +x /docker-entrypoint-initdb.d/init-user.sh
