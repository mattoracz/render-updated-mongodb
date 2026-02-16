#!/bin/bash
set -e

if [ -n "$MONGO_NON_ROOT_USERNAME" ] && [ -n "$MONGO_NON_ROOT_PASSWORD" ] && [ -n "$MONGO_NON_ROOT_DATABASE" ]; then
  mongosh admin --quiet --eval "
    db = db.getSiblingDB('$MONGO_NON_ROOT_DATABASE');
    db.createUser({
      user: '$MONGO_NON_ROOT_USERNAME',
      pwd: '$MONGO_NON_ROOT_PASSWORD',
      roles: [{ role: 'readWrite', db: '$MONGO_NON_ROOT_DATABASE' }]
    })
  "
  echo "User '$MONGO_NON_ROOT_USERNAME' created on database '$MONGO_NON_ROOT_DATABASE'."
else
  echo "Skipping non-root user creation (MONGO_NON_ROOT_USERNAME, MONGO_NON_ROOT_PASSWORD, or MONGO_NON_ROOT_DATABASE not set)."
fi
