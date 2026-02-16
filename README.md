# Deploy MongoDB on Render

This repo can be used to deploy [MongoDB] on Render.

The [`Dockerfile`](./Dockerfile) on the `master` branch points to latest stable MongoDB version (**8.0**). We also provide dockerfiles for specific MongoDB release lines in this repository in appropriate branches.

## Environment Variables

| Variable | Description |
|---|---|
| `MONGO_INITDB_ROOT_USERNAME` | Root (admin) username |
| `MONGO_INITDB_ROOT_PASSWORD` | Root (admin) password (auto-generated on Render) |
| `MONGO_NON_ROOT_USERNAME` | Application-level database user |
| `MONGO_NON_ROOT_PASSWORD` | Application-level database password (auto-generated on Render) |
| `MONGO_NON_ROOT_DATABASE` | Database name for the non-root user |

On first startup, MongoDB will create the root user and then run `init-user.sh` to create the non-root application user with `readWrite` access to the specified database.

## Deployment

### One Click

Use the button below to deploy MongoDB on Render.

[![Deploy to Render](http://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

### Manual

See the guide at https://render.com/docs/deploy-mongodb.

If you need help, chat with us at https://render.com/chat.

[MongoDB]: https://www.mongodb.com/
