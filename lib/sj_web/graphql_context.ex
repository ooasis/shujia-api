defmodule SJWeb.GraphqlContext do
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _) do
    Absinthe.Plug.put_options(
      conn,
      context: %{
        user: SJ.Guardian.Plug.current_resource(conn),
        claims: SJ.Guardian.Plug.current_claims(conn)
      }
    )
  end

end