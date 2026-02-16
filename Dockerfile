FROM mongodb/mongodb-community-server:8.0-ubuntu2204

COPY init-user.sh /docker-entrypoint-initdb.d/init-user.sh
