#!/bin/bash
set -e

INIT_FLAG="/data/db/.user_initialized"

if [ ! -f "$INIT_FLAG" ]; then
  echo "First startup detected, initializing users..."

  mongod --bind_ip 127.0.0.1 --noauth &
  MONGOD_PID=$!

  until mongosh --quiet --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
    sleep 1
  done

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
  echo "Initialization complete. Stopping temporary mongod..."

  kill "$MONGOD_PID"
  wait "$MONGOD_PID" 2>/dev/null || true
else
  echo "Already initialized, skipping user creation."
fi

echo "Starting MongoDB with --auth..."
exec mongod --bind_ip_all --auth
