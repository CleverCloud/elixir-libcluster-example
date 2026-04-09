# demo-elixir — Erlang Clustering on Clever Cloud

A minimal Phoenix application demonstrating automatic Erlang node clustering
on Clever Cloud using **Network Groups** and **libcluster** (DNSPoll strategy).

Each instance is named `demo@<wg_ip>`, libcluster resolves the Network Group DNS
to discover peers and calls `Node.connect/1`.

## Architecture

```
Instance A (demo@10.103.0.23)       Instance B (demo@10.103.0.24)
       │                                     │
       └───── Erlang Distribution ───────────┘
                 (ports 9000-9010)

CC_NG_MEMBER_DNS → multi-A DNS → [10.103.0.23, 10.103.0.24]
              libcluster DNSPoll (every 5s)
```

## Endpoints

| Route | Description |
|---|---|
| `GET /` | `Hello from demo@<wg_ip>` |
| `GET /cluster` | HTML page with auto-refresh every 5s |
| `GET /cluster` (Accept: application/json) | `{"node":"demo@...","peers":[...],"total":N}` |

## Prerequisites

- [Clever Tools CLI](https://github.com/CleverCloud/clever-tools) installed and authenticated (`clever login`)
- An Elixir application created on Clever Cloud

## Full Deployment

### 1. Create the Clever Cloud application

```sh
clever create --type elixir demo-elixir
# Note the returned <appId>
```

### 2. Create and configure the Network Group

```sh
# Create the Network Group
clever ng create elixir-demo
# → Note the returned <ngId> (e.g. ng_f16407b9-...)

# Link the application to the Network Group
clever ng link <appId> <ngId>

# Get the application memberID
clever ng get <ngId>
# → Find the "application" member and note its id (e.g. app_aeea38e4-...)
```

### 3. Set environment variables

```sh
# Elixir version (required)
clever env set CC_ELIXIR_VERSION "1.18"

# Startup with Erlang distribution (via scripts/start.sh)
clever env set CC_RUN_COMMAND "scripts/start.sh"

# No database
clever env set CC_PHOENIX_RUN_ECTO_MIGRATE "false"

# Shared cookie across all instances (must be identical)
clever env set RELEASE_COOKIE "$(openssl rand -hex 32)"

# DNS of the member in the Network Group
# Format: <memberID>.m.<ngId>.cc-ng.cloud
clever env set CC_NG_MEMBER_DNS "<memberID>.m.<ngId>.cc-ng.cloud"

# Phoenix secret key
clever env set SECRET_KEY_BASE "$(openssl rand -hex 64)"

# Application domain
clever env set APP_DOMAIN "<appId>.cleverapps.io"
```

### 4. Deploy

```sh
clever deploy
```

### 5. Scale to multiple instances

```sh
clever scale --min-instances 2 --max-instances 4
```

## Verification

```sh
# Each request may hit a different instance
curl https://<app-domain>/
# → Hello from demo@10.103.0.23

curl -H "Accept: application/json" https://<app-domain>/cluster
# → {"node":"demo@10.103.0.23","peers":["demo@10.103.0.24"],"total":2}

# HTML page with auto-refresh
open https://<app-domain>/cluster
```

In Clever Cloud logs:

```
[ClusterMonitor] Started on demo@10.103.0.23. Current peers: []
[ClusterMonitor] nodeup: demo@10.103.0.24 | cluster: [:"demo@10.103.0.24"]
```

## How It Works

### Startup (`scripts/start.sh`)

On each instance startup, `scripts/start.sh`:

1. Detects the WireGuard interface (`wg-*`) via `ip -o addr show`
2. Retrieves the instance's WireGuard IP
3. Starts `mix phx.server` with `elixir --name demo@<wg_ip>`

In OTP 26+, Erlang distribution must be enabled at VM startup (via `--name`);
it can no longer be started afterwards with `Node.start/1`.

### Peer Discovery (libcluster)

In `config/runtime.exs`, libcluster is configured with the `DNSPoll` strategy:

- Resolves `CC_NG_MEMBER_DNS` every 5 seconds
- This DNS returns one A record per live instance in the Network Group
- libcluster builds `demo@<ip>` for each IP and calls `Node.connect/1`

### Monitoring (`Demo.ClusterMonitor`)

A GenServer subscribes to `:nodeup` and `:nodedown` events via
`:net_kernel.monitor_nodes/1` and logs them.

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `CC_ELIXIR_VERSION` | yes | Elixir version (e.g. `1.18`) |
| `CC_RUN_COMMAND` | yes | `scripts/start.sh` |
| `CC_PHOENIX_RUN_ECTO_MIGRATE` | yes | `false` (no database) |
| `RELEASE_COOKIE` | yes | Shared Erlang cookie across all instances |
| `CC_NG_MEMBER_DNS` | yes | `<memberID>.m.<ngId>.cc-ng.cloud` |
| `SECRET_KEY_BASE` | yes | Phoenix secret key (min. 64 bytes) |
| `APP_DOMAIN` | recommended | Public application domain |

> `RELEASE_NODE` should **not** be set manually.
> `scripts/start.sh` builds it dynamically from the WireGuard IP.

## Local Development

```sh
mix deps.get
mix phx.server
# → http://localhost:4000
```

In dev, clustering is disabled (`config/dev.exs`: `topologies: []`).

## Project Structure

```
├── scripts/start.sh                  ← Clever Cloud startup script
├── mix.exs                       ← deps: phoenix, bandit, libcluster, jason
├── config/
│   ├── config.exs                ← base Phoenix config
│   ├── dev.exs                   ← dev, clustering disabled
│   ├── prod.exs                  ← log level :info
│   └── runtime.exs               ← libcluster DNSPoll + prod endpoint
├── rel/
│   ├── env.sh.eex                ← (optional, for release-based deployment)
│   └── vm.args.eex               ← (optional, for release-based deployment)
├── lib/
│   ├── demo/
│   │   ├── application.ex        ← Cluster.Supervisor + ClusterMonitor + Endpoint
│   │   └── cluster_monitor.ex    ← GenServer :nodeup/:nodedown
│   └── demo_web/
│       ├── endpoint.ex
│       ├── router.ex             ← GET / and GET /cluster
│       └── controllers/
│           ├── page_controller.ex
│           └── cluster_controller.ex
└── README.md
```
