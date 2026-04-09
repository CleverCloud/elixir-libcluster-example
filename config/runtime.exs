import Config

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE env var is not set. Generate one with: mix phx.gen.secret"

  config :demo, DemoWeb.Endpoint,
    http: [port: String.to_integer(System.get_env("PORT", "4000"))],
    url: [host: System.get_env("APP_DOMAIN", "localhost"), port: 443, scheme: "https"],
    secret_key_base: secret_key_base,
    server: true

  # libcluster DNS via Clever Cloud Network Groups.
  # CC_NG_MEMBER_DNS must be: <memberID>.m.<ngID>.cc-ng.cloud
  # This DNS name resolves to one A record per live instance (their WireGuard IP).
  if dns = System.get_env("CC_NG_MEMBER_DNS") do
    config :libcluster,
      topologies: [
        cc_ng: [
          strategy: Cluster.Strategy.DNSPoll,
          config: [
            # DNS name to resolve (multi-A record → one IP per instance)
            query: dns,
            # Must match the left part of RELEASE_NODE (demo@<ip>)
            node_basename: "demo",
            polling_interval: 5_000
          ]
        ]
      ]
  end
end
