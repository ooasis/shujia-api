defmodule SJ.Mixfile do
  use Mix.Project

  def project do
    [
      app: :sj,
      version: "0.0.1",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {SJ.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :postgrex,
        :ueberauth,
        :ueberauth_google,
        :ueberauth_facebook,
        :ueberauth_identity,
        :comeonin,
        :bamboo,
        :recaptcha,
        :absinthe
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.3"},
      {:jason, "~> 1.1.0"},
      {:decimal, "~> 1.9"},
      {:postgrex, "~> 0.15"},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.18"},
      {:cowboy, "~> 2.9"},
      {:plug_cowboy, "~> 2.5"},
      {:ecto_enum, "~> 1.4"},
      {:argon2_elixir, "~> 2.4"},
      {:comeonin, "~> 5.3"},
      {:cors_plug, "~> 2.0"},
      {:absinthe_plug, "~> 1.5"},
      {:bamboo, "~> 2.1.0"},
      {:bamboo_smtp, "~> 4.0"},
      {:bamboo_phoenix, "~> 1.0"},
      {:recaptcha, "~> 3.1"},
      {:ueberauth, "~> 0.6"},
      {:ueberauth_google, "~> 0.9"},
      {:ueberauth_facebook, "~> 0.8"},
      {:ueberauth_identity, "~> 0.3"},
      {:guardian, "~> 2.2"},
      {:guardian_phoenix, "~> 2.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
