# System files

Run these commands from the repository root. Chezmoi skips `etc/`.

## Docker volume watcher

Install the watcher and enable it for the system Docker daemon:

```sh
chezmoi apply ~/.scripts/docker-volume-watch
sudo install -Dm644 etc/systemd/system/docker-volume-watch.service /etc/systemd/system/docker-volume-watch.service
sudo systemctl daemon-reload
sudo systemctl enable --now docker-volume-watch.service
```

The service starts and stops with Docker. It runs as `pbogut` with access to
the Docker socket and uses `notify-send` for desktop notifications. For a
different desktop account, update `User=` and the home path in `ExecStart=`.

Check the journal if you missed a notification or were logged out:

```sh
journalctl -u docker-volume-watch.service --since today
```

Look for `Created anonymous volume` and `Mounted anonymous volume`. Both lines
include the full volume ID. The mount entry adds the container, destination,
and Compose project and service when available. The first mount also updates
the desktop notification.

Docker can't rename an existing volume. To prevent another anonymous volume,
give the mount a name in Compose or `docker run`. If you need the existing
data, migrate it to the named volume before switching the container over.

After editing the watcher, apply the script and restart the service:

```sh
chezmoi apply ~/.scripts/docker-volume-watch
sudo systemctl restart docker-volume-watch.service
```

If you edit the unit, repeat the `sudo install` and `daemon-reload` commands
before restarting the service.
