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
| `RENDER_SSH_PUBLIC_KEY` | Your SSH public key (one line from `~/.ssh/id_ed25519.pub`) so you can SSH into the container and use Studio 3T over SSH tunnel |

On first startup, `entrypoint.sh` starts mongod without auth, creates the root and app users, then restarts mongod with `--auth`. On subsequent startups, user creation is skipped. Connect without TLS: `mongodb://USER:PASS@HOST:27017/DB`.

### Connecting from Studio 3T (SSH tunnel)

1. In Render Dashboard: add env var **`RENDER_SSH_PUBLIC_KEY`** with the contents of your `~/.ssh/id_ed25519.pub` (one line). Redeploy.
2. In Studio 3T: **New Connection** → **Connect via SSH** tab:
   - **SSH host:** `ssh.oregon.render.com` (or your region, e.g. `ssh.frankfurt.render.com`)
   - **SSH port:** 22
   - **SSH user:** your Render **service ID** (e.g. `srv-d69fvnjh46gs73ft7va0` — from Dashboard → service → Connect → SSH)
   - **Authentication:** Use public key → choose your private key (e.g. `~/.ssh/id_ed25519`)
3. **MongoDB** tab: **Host:** `localhost`, **Port:** 27017, **Authentication** with your MongoDB user/password. **SSL/TLS:** Off.
4. Save and connect.

## Deployment

### One Click

Use the button below to deploy MongoDB on Render.

[![Deploy to Render](http://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

### Manual

See the guide at https://render.com/docs/deploy-mongodb.

If you need help, chat with us at https://render.com/chat.

[MongoDB]: https://www.mongodb.com/
