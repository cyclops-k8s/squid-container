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

| Mount                   | Purpose                                        |
| ----------------------- | ---------------------------------------------- |
| `/squid-state`          | Persistent TLS certificate database (`ssl_db`) |
| `/etc/squid/squid.conf` | Your Squid configuration file                  |

Squid listens on port **3128** by default.

### Health Check

The image ships with a `HEALTHCHECK` that verifies the init process (PID 1) is still alive, so orchestration platforms can detect hung containers.

## How It Works

1. **Builder stage** — installs build dependencies, clones Squid v7, bootstraps, configures with a comprehensive set of features (ESI, ICAP, delay pools, cache digests, etc.), and compiles.
2. **Runtime stage** — copies the built artifacts into a clean Ubuntu 26.04 image with only the required shared libraries, sets ownership for the `proxy` user, and uses `entrypoint.sh` to initialize caches before starting Squid in the foreground.

## Entrypoint

The [entrypoint.sh](entrypoint.sh) script:

1. Generates the TLS certificate cache at `/squid-state/ssl_db` if it does not already exist (`security_file_certgen`).
2. Removes any stale `/run/squid.pid` left behind by a previous run.
3. Initializes the Squid swap/cache directories (`squid -zN`), failing hard if it cannot.
4. Validates the configuration parses cleanly (`squid -k parse`).
5. Starts Squid in the foreground bound to the mounted config (`exec squid -NYCd 1 -f /etc/squid/squid.conf`).

## License

[MIT](LICENSE)
