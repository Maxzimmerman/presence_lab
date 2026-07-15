defmodule PresenceLabWeb.Plugs.RequireAuth do
  use PresenceLabWeb, :controller
  import Plug.Conn

  def init(_params) do
  end

  def call(conn, _params) do
    IO.puts("called")
    IO.inspect(conn.assigns.user)

    if user = conn.assigns.user do
      conn
    else
      conn
      |> put_flash(:error, "You must log in first")
      |> redirect(to: ~p"/auth/login")
      |> halt()
    end
  end
end
