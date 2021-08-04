defmodule SJWeb.Router do
  use SJWeb, :router

  pipeline :rest do
    plug(:accepts, ["json"])
  end

  pipeline :rest_auth do
    plug(SJWeb.Guardian.SJPipeline)
    plug(:accepts, ["json"])
  end

  pipeline :gapi do
    plug(SJWeb.Guardian.SJPipeline)
    plug(SJWeb.GraphqlContext)
  end

  scope "/auth", SJWeb do
    pipe_through([:rest])

    post("/request_change_token", AuthController, :request_change_token)
    post("/reset_password", AuthController, :reset_password)
    post("/verify", AuthController, :verify)
    post("/:provider/callback", AuthController, :callback)
  end

  scope "/authed", SJWeb do
    pipe_through([:rest_auth])

    post("/create", AuthController, :create)
    post("/change_password", AuthController, :change_password)
    get("/user", AuthController, :get_user)
    get("/logout", AuthController, :delete)
  end

  scope "/gapi" do
    pipe_through([:gapi])

    forward("/", Absinthe.Plug,
      schema: SJ.GraphqlSchema,
      json_codec: Jason
    )
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    pipeline :graphql do
      plug(SJWeb.GraphqlContext)
    end

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_flash)
      plug(:protect_from_forgery)
      plug(:put_secure_browser_headers)
    end

    scope "/" do
      pipe_through(:browser)
      live_dashboard("/dashboard", metrics: SJWeb.Telemetry)
    end

    scope "/graphql" do
      pipe_through([:graphql])

      forward("/", Absinthe.Plug.GraphiQL,
        schema: SJ.GraphqlSchema,
        json_codec: Jason
      )
    end
  end
end
