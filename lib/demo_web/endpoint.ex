defmodule DemoWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :demo

  @session_options [
    store: :cookie,
    key: "_demo_key",
    signing_salt: "cF3xZ9pQ",
    same_site: "Lax"
  ]

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug DemoWeb.Router
end
