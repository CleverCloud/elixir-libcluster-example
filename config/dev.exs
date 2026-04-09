import Config

config :demo, DemoWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  secret_key_base: "dev_secret_key_base_at_least_64_bytes_long_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

config :logger, level: :debug

# Pas de clustering en dev
config :libcluster, topologies: []
