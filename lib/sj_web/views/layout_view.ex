defmodule SJWeb.LayoutView do
  use SJWeb, :view
  import Guardian.Plug

  def cur_user(conn) do
    current_resource(conn)
  end
end
