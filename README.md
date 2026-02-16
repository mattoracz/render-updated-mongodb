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

On first startup, `entrypoint.sh` starts mongod without auth, creates the root and app users, then restarts mongod with `--auth`. On subsequent startups, user creation is skipped. Connect without TLS: `mongodb://USER:PASS@HOST:27017/DB`.

## Deployment

### One Click

Use the button below to deploy MongoDB on Render.

[![Deploy to Render](http://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

### Manual

See the guide at https://render.com/docs/deploy-mongodb.

If you need help, chat with us at https://render.com/chat.

[MongoDB]: https://www.mongodb.com/
