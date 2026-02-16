# Deploy MongoDB on Render

This repo can be used to deploy [MongoDB] on Render.

The [`Dockerfile`](./Dockerfile) on the `master` branch uses the official [`mongodb/mongodb-community-server:8.0-ubuntu2204`](https://hub.docker.com/r/mongodb/mongodb-community-server) image.

## Environment Variables

| Variable | Description |
|---|---|
| `MONGO_INITDB_ROOT_USERNAME` | Root (admin) username |
| `MONGO_INITDB_ROOT_PASSWORD` | Root (admin) password |
| `MONGO_NON_ROOT_USERNAME` | Application-level database user |
| `MONGO_NON_ROOT_PASSWORD` | Application-level database password |
| `MONGO_NON_ROOT_DATABASE` | Database name for the non-root user |

On first startup, the image automatically creates the root user from `MONGO_INITDB_ROOT_USERNAME`/`MONGO_INITDB_ROOT_PASSWORD`. The `init-user.sh` script in `/docker-entrypoint-initdb.d/` then creates the non-root application user with `readWrite` access to the specified database.

## Deployment

### One Click

Use the button below to deploy MongoDB on Render.

[![Deploy to Render](http://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

### Manual

See the guide at https://render.com/docs/deploy-mongodb.

If you need help, chat with us at https://render.com/chat.

[MongoDB]: https://www.mongodb.com/
