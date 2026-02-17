FROM mongodb/mongodb-community-server:8.0-ubuntu2204

USER root
# Remove/disable native sshd so Render's SSH connectivity works (don't run our own sshd)
RUN apt-get update \
    && apt-get install -y --no-install-recommends gosu \
    && (apt-get remove -y --purge openssh-server openssh-sftp-server 2>/dev/null || true) \
    && (systemctl disable ssh 2>/dev/null || true) \
    && rm -rf /var/lib/apt/lists/*
COPY --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
