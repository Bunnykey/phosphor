import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/nx_live_viz start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :nx_live_viz, NxLiveVizWeb.Endpoint, server: true
end

config :nx_live_viz, NxLiveVizWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  # Required: Server configuration
  host = System.get_env("PHX_HOST") || "localhost"
  port = String.to_integer(System.get_env("PORT") || "4000")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE environment variable is not set"

  if byte_size(secret_key_base) < 64 do
    raise "SECRET_KEY_BASE must be at least 64 bytes"
  end

  config :nx_live_viz, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :nx_live_viz, NxLiveVizWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base,
    server: true

  # Optional: EXLA configuration
  if xla_target = System.get_env("XLA_TARGET") do
    config :exla, :default_client, xla_target
  end
end
