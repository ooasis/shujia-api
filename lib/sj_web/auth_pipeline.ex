defmodule SJWeb.Guardian.SJPipeline do
  @claims %{typ: "access"}

  use Guardian.Plug.Pipeline,
      otp_app: :sj,
      module: SJ.Guardian,
      error_handler: SJWeb.AuthController

  plug Guardian.Plug.VerifyHeader, claims: @claims, schema: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, ensure: true
end