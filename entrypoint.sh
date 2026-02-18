#!/bin/bash
set -e

INIT_FLAG="/data/db/.initialized"

# Fix ownership for existing data (e.g. from previous deploy)
chown -R mongodb:mongodb /data/db 2>/dev/null || true

wait_for_mongod() {
  echo "==> Waiting for mongod to accept connections (timeout 60s)..."
  local max=60
  for i in $(seq 1 "$max"); do
    if gosu mongodb mongosh --host 127.0.0.1 --port 27017 --quiet --norc --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
      echo "==> mongod is ready (after ${i}s)."
      return 0
    fi
    [ "$i" -eq 1 ] && sleep 2 || sleep 1
  done
  echo "==> ERROR: mongod did not become ready in ${max}s"
  exit 1
}

# Always start temp mongod to check/create users (handles: first run, or .initialized without users)
echo "==> Starting temporary mongod (noauth, 127.0.0.1) to ensure users exist..."
gosu mongodb mongod --bind_ip 127.0.0.1 --port 27017 --dbpath /data/db --noauth &
MONGOD_PID=$!
wait_for_mongod

USER_COUNT=$(gosu mongodb mongosh --host 127.0.0.1 --port 27017 --quiet --norc --eval "
  db.getSiblingDB('admin').getUsers().length
" 2>/dev/null || echo "0")

NEED_CREATE=0
if [ "$USER_COUNT" = "0" ] || [ -z "$USER_COUNT" ]; then
  if [ -n "$MONGO_INITDB_ROOT_USERNAME" ] && [ -n "$MONGO_INITDB_ROOT_PASSWORD" ]; then
    NEED_CREATE=1
  else
    echo "==> ERROR: No users in admin and MONGO_INITDB_ROOT_USERNAME/MONGO_INITDB_ROOT_PASSWORD are not set."
    echo "==> Set these env vars in Render Dashboard (Environment) and redeploy."
    kill "$MONGOD_PID" 2>/dev/null || true
    exit 1
  fi
fi

if [ "$NEED_CREATE" = "1" ]; then
  echo "==> Creating users (no users found or first init)..."

  if [ -n "$MONGO_INITDB_ROOT_USERNAME" ] && [ -n "$MONGO_INITDB_ROOT_PASSWORD" ]; then
    gosu mongodb mongosh --host 127.0.0.1 --port 27017 --quiet --norc --eval "
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
    gosu mongodb mongosh --host 127.0.0.1 --port 27017 --quiet --norc --eval "
      use $MONGO_NON_ROOT_DATABASE
      db.createUser({
        user: '$MONGO_NON_ROOT_USERNAME',
        pwd: '$MONGO_NON_ROOT_PASSWORD',
        roles: [{ role: 'readWrite', db: '$MONGO_NON_ROOT_DATABASE' }]
      })
    "
    echo "==> App user '$MONGO_NON_ROOT_USERNAME' created on '$MONGO_NON_ROOT_DATABASE'."
  fi
else
  echo "==> Users already exist (count: $USER_COUNT), skipping user creation."
fi

gosu mongodb touch "$INIT_FLAG"
echo "==> Shutting down temp mongod (graceful)..."
gosu mongodb mongosh --host 127.0.0.1 --port 27017 --quiet --norc --eval "db.adminCommand({ shutdown: 1 })" >/dev/null 2>&1 || true
wait "$MONGOD_PID" 2>/dev/null || true
echo "==> Temp mongod stopped."

echo "==> Starting mongod with auth (foreground, bind_ip_all)..."
exec gosu mongodb mongod --bind_ip_all --port 27017 --dbpath /data/db --auth
