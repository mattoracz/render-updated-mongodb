#!/bin/bash
set -e

INIT_FLAG="/data/db/.user_initialized"

mongod --bind_ip_all --fork --logpath /var/log/mongodb/mongod.log

until mongosh --quiet --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
  sleep 1
done

if [ ! -f "$INIT_FLAG" ]; then
  if [ -n "$MONGO_INITDB_ROOT_USERNAME" ] && [ -n "$MONGO_INITDB_ROOT_PASSWORD" ]; then
    mongosh admin --quiet --eval "
      db.createUser({
        user: '$MONGO_INITDB_ROOT_USERNAME',
        pwd: '$MONGO_INITDB_ROOT_PASSWORD',
        roles: [{ role: 'root', db: 'admin' }]
      })
    "
    echo "Root user '$MONGO_INITDB_ROOT_USERNAME' created."
  fi

  if [ -n "$MONGO_NON_ROOT_USERNAME" ] && [ -n "$MONGO_NON_ROOT_PASSWORD" ] && [ -n "$MONGO_NON_ROOT_DATABASE" ]; then
    mongosh admin --quiet \
      -u "$MONGO_INITDB_ROOT_USERNAME" \
      -p "$MONGO_INITDB_ROOT_PASSWORD" \
      --eval "
        db = db.getSiblingDB('$MONGO_NON_ROOT_DATABASE');
        db.createUser({
          user: '$MONGO_NON_ROOT_USERNAME',
          pwd: '$MONGO_NON_ROOT_PASSWORD',
          roles: [{ role: 'readWrite', db: '$MONGO_NON_ROOT_DATABASE' }]
        })
      "
    echo "User '$MONGO_NON_ROOT_USERNAME' created on database '$MONGO_NON_ROOT_DATABASE'."
  fi

  touch "$INIT_FLAG"
  echo "Initialization complete."
else
  echo "Already initialized, skipping user creation."
fi

mongosh admin --quiet --eval "db.shutdownServer()" > /dev/null 2>&1 || true
sleep 2

exec mongod --bind_ip_all --auth
