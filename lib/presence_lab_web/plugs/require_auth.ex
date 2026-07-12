defmodule PresenceLabWeb.Plugs.RequireAuth do
  use PresenceLabWeb, :controller
  import Plug.Conn

  def init(_params) do
  end

  def call(conn, _params) do
    IO.inspect(conn, libmit: :infinity)

    if conn.assigns["user_id"] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in first")
      |> redirect(to: ~p"/auth/register")
      |> halt()
    end
  end
end
