# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

host = System.get_env("HOST") || "localhost"
port = System.get_env("PORT") || "4000"

config :phoenix, :json_library, Jason

# General application configuration
config :sj,
  ecto_repos: [SJ.Repo]

config :sj,
       SJWeb.Endpoint,
       #  secret_key_base: "OverrideMe",
       #  live_view: [signing_salt: "OverrideMe"],
       url: [
         host: host
       ],
       http: [
         port: port
       ],
       render_errors: [
         view: SJWeb.ErrorView,
         accepts: ~w(html json)
       ],
       pubsub_server: SJ.PubSub

config :logger,
       :console,
       format: "$time $metadata[$level] $message\n",
       metadata: [:user_id, :request_id]

config :ueberauth,
       Ueberauth,
       providers: [
         google: {Ueberauth.Strategy.Google, [default_scope: "profile"]},
         facebook: {Ueberauth.Strategy.Facebook, []},
         identity:
           {Ueberauth.Strategy.Identity,
            [
              callback_methods: ["POST"],
              request_path: "/"
            ]}
       ]

config :ueberauth,
       Ueberauth.Strategy.Google.OAuth,
       #  client_id: "OverrideMe",
       #  client_secret: "OverrideMe",
       redirect_uri: "http://#{host}:#{port}/auth/google/callback"

config :ueberauth,
       Ueberauth.Strategy.Facebook.OAuth,
       #  client_id: "OverrideMe",
       #  client_secret: "OverrideMe",
       redirect_uri: "http://#{host}:#{port}/auth/facebook/callback"

config :sj,
       SJ.Guardian,
       #  secret: "OverrideMe",
       #  secret_key: "OverrideMe",
       issuer: "Ooasis"

config :sj,
       SJ.Mailer,
       adapter: Bamboo.SMTPAdapter,
       #  server: "OverrideMe",
       #  port: 0,
       #  username: "OverrideMe",
       #  password: "OverrideMe",
       tls: :if_available,
       # can be `:always` or `:never`
       ssl: false,
       # can be `true`
       retries: 1

# config :recaptcha,
#   public_key: {:system, "OverrideMe"},
#   secret: {:system, "OverrideMe"}

config :cors_plug,
  origin: ["http://#{host}:3000"],
  max_age: 86400,
  methods: ["GET", "POST"]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
