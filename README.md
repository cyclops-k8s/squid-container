# squid-container

A Docker image that builds [Squid](http://www.squid-cache.org/) v7 from source on Ubuntu 26.04, with SSL/TLS bump support baked in.

## Features

- **Built from source** — clones the Squid v7 branch and compiles with Ubuntu-hardened compiler flags (stack protector, FORTIFY_SOURCE, RELRO, etc.).
- **SSL Bump / HTTPS interception** — compiled with `--enable-ssl-crtd` and `--with-openssl`; the entrypoint auto-generates the TLS certificate cache on startup.
- **Multi-stage build** — final image contains only runtime dependencies (`ca-certificates`, `libltdl7`), keeping it small.
- **Runs as non-root** — the container runs as the `proxy` user.

## Quick Start

### Build

```bash
docker build -t squid .
```

### Run

```bash
docker run -d \
  -p 3128:3128 \
  -v squid-state:/squid-state \
  -v /path/to/squid.conf:/etc/squid/squid.conf:ro \
  squid
```

| Mount | Purpose |
|---|---|
| `/squid-state` | Persistent TLS certificate database (`ssl_db`) |
| `/etc/squid/squid.conf` | Your Squid configuration file |

Squid listens on port **3128** by default.

### Logs

Access and store logs are tailed to stdout automatically by the entrypoint, so `docker logs` works out of the box.

## How It Works

1. **Builder stage** — installs build dependencies, clones Squid v7, bootstraps, configures with a comprehensive set of features (ESI, ICAP, delay pools, cache digests, etc.), and compiles.
2. **Runtime stage** — copies the built artifacts into a clean Ubuntu 26.04 image with only the required shared libraries, sets ownership for the `proxy` user, and uses `entrypoint.sh` to initialize caches before starting Squid in the foreground.

## Entrypoint

The [entrypoint.sh](entrypoint.sh) script:

1. Generates the TLS certificate cache at `/squid-state/ssl_db`.
2. Creates Squid swap/cache directories (`squid -zN`).
3. Tails access and store logs to stdout.
4. Starts Squid in the foreground (`squid -NYCd 1`).

## License

[MIT](LICENSE)
