#!/bin/bash
set -e

INIT_FLAG="/data/db/.initialized"
MONGOSH_CMD="mongosh --host 127.0.0.1 --port 27017 --quiet --norc --nodb --eval"

wait_for_mongod() {
  echo "Waiting for mongod to accept connections..."
  for i in $(seq 1 30); do
    if mongosh --host 127.0.0.1 --port 27017 --quiet --norc --eval "db.adminCommand('ping')" 2>/dev/null | grep -q ok; then
      echo "mongod is ready."
      return 0
    fi
    sleep 1
  done
  echo "ERROR: mongod did not become ready in 30s"
  exit 1
}

if [ ! -f "$INIT_FLAG" ]; then
  echo "==> First startup, initializing..."

  mongod --bind_ip 127.0.0.1 --port 27017 --dbpath /data/db --noauth &
  MONGOD_PID=$!
  wait_for_mongod

  if [ -n "$MONGO_INITDB_ROOT_USERNAME" ] && [ -n "$MONGO_INITDB_ROOT_PASSWORD" ]; then
    mongosh --host 127.0.0.1 --port 27017 --quiet --norc --eval "
      use admin
      db.createUser({
        user: '$MONGO_INITDB_ROOT_USERNAME',
        pwd: '$MONGO_INITDB_ROOT_PASSWORD',
        roles: ['root']
      })
    "
    echo "==> Root user '$MONGO_INITDB_ROOT_USERNAME' created."
  fi

  if [ -n "$MONGO_NON_ROOT_USERNAME" ] && [ -n "$MONGO_NON_ROOT_PASSWORD" ] && [ -n "$MONGO_NON_ROOT_DATABASE" ]; then
    mongosh --host 127.0.0.1 --port 27017 --quiet --norc --eval "
      use $MONGO_NON_ROOT_DATABASE
      db.createUser({
        user: '$MONGO_NON_ROOT_USERNAME',
        pwd: '$MONGO_NON_ROOT_PASSWORD',
        roles: [{ role: 'readWrite', db: '$MONGO_NON_ROOT_DATABASE' }]
      })
    "
    echo "==> App user '$MONGO_NON_ROOT_USERNAME' created on '$MONGO_NON_ROOT_DATABASE'."
  fi

  touch "$INIT_FLAG"
  echo "==> Initialization complete. Shutting down temp mongod..."
  kill "$MONGOD_PID"
  wait "$MONGOD_PID" 2>/dev/null || true
else
  echo "==> Already initialized, skipping user creation."
fi

echo "==> Starting mongod with auth..."
exec mongod --bind_ip_all --port 27017 --dbpath /data/db --auth
