#!/bin/bash
set -e

INIT_FLAG="/data/db/.user_initialized"
DATA_DIR="/data/db"
MONGO_URI="mongodb://127.0.0.1:27017"

# Clean up incompatible data from older MongoDB versions (e.g. 4.2)
if [ -f "$DATA_DIR/WiredTiger" ] && [ ! -f "$INIT_FLAG" ]; then
  echo "Detected old data files without init flag. Cleaning up incompatible data..."
  find "$DATA_DIR" -mindepth 1 -delete
  echo "Old data removed."
fi

# Fix ownership on the data directory
chown -R mongodb:mongodb "$DATA_DIR"

if [ ! -f "$INIT_FLAG" ]; then
  echo "First startup detected, initializing users..."

  gosu mongodb mongod --bind_ip 127.0.0.1 --noauth &
  MONGOD_PID=$!

  echo "Waiting for mongod to be ready..."
  for i in $(seq 1 30); do
    if gosu mongodb mongosh "$MONGO_URI" --quiet --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
      echo "mongod is ready."
      break
    fi
    if [ "$i" -eq 30 ]; then
      echo "ERROR: mongod did not start in time."
      exit 1
    fi
    sleep 1
  done

  if [ -n "$MONGO_INITDB_ROOT_USERNAME" ] && [ -n "$MONGO_INITDB_ROOT_PASSWORD" ]; then
    gosu mongodb mongosh "$MONGO_URI/admin" --quiet --eval "
      db.createUser({
        user: '$MONGO_INITDB_ROOT_USERNAME',
        pwd: '$MONGO_INITDB_ROOT_PASSWORD',
        roles: [{ role: 'root', db: 'admin' }]
      })
    "
    echo "Root user '$MONGO_INITDB_ROOT_USERNAME' created."
  fi

  if [ -n "$MONGO_NON_ROOT_USERNAME" ] && [ -n "$MONGO_NON_ROOT_PASSWORD" ] && [ -n "$MONGO_NON_ROOT_DATABASE" ]; then
    gosu mongodb mongosh "$MONGO_URI/admin" --quiet \
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

  gosu mongodb touch "$INIT_FLAG"
  echo "Initialization complete. Stopping temporary mongod..."

  kill "$MONGOD_PID"
  wait "$MONGOD_PID" 2>/dev/null || true
else
  echo "Already initialized, skipping user creation."
fi

echo "Starting MongoDB with --auth..."
exec gosu mongodb mongod --bind_ip_all --auth
