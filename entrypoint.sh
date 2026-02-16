#!/bin/bash
set -e

INIT_FLAG="/data/db/.initialized"

# Optional: enable SSH for Render SSH / Studio 3T tunnel
if [ -n "$RENDER_SSH_PUBLIC_KEY" ]; then
  echo "$RENDER_SSH_PUBLIC_KEY" >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  /usr/sbin/sshd
  echo "==> SSHD started (RENDER_SSH_PUBLIC_KEY set)."
fi

# Fix ownership for existing data (e.g. from previous deploy)
chown -R mongodb:mongodb /data/db 2>/dev/null || true

wait_for_mongod() {
  echo "Waiting for mongod to accept connections..."
  for i in $(seq 1 30); do
    if gosu mongodb mongosh --host 127.0.0.1 --port 27017 --quiet --norc --eval "db.adminCommand('ping')" 2>/dev/null | grep -q ok; then
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

  gosu mongodb mongod --bind_ip 127.0.0.1 --port 27017 --dbpath /data/db --noauth &
  MONGOD_PID=$!
  wait_for_mongod

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

  gosu mongodb touch "$INIT_FLAG"
  echo "==> Initialization complete. Shutting down temp mongod..."
  kill "$MONGOD_PID"
  wait "$MONGOD_PID" 2>/dev/null || true
else
  echo "==> Already initialized, skipping user creation."
fi

echo "==> Starting mongod with auth..."
exec gosu mongodb mongod --bind_ip_all --port 27017 --dbpath /data/db --auth
