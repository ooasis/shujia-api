defmodule SJWeb.ControllerHelpers do
  import Plug.Conn
  import Phoenix.Controller
  import SJWeb.ErrorHelpers

  def render_json(conn, response) do
    case response do
      {status, data} ->
        conn
        |> put_status(status)
        |> json(%{data: data})

      {status, err, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(status)
        |> json(%{err: err, data: encode_changeset_error(changeset)})

      {status, err, data} ->
        conn
        |> put_status(status)
        |> json(%{err: err, data: data})
    end
  end
end
