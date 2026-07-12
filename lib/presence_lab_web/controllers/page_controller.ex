defmodule PresenceLabWeb.PageController do
  use PresenceLabWeb, :controller

  plug PresenceLabWeb.Plugs.RequireAuth

  def home(conn, _params) do
    render(conn, :home)
  end
end
