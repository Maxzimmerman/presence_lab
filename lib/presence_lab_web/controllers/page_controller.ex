defmodule PresenceLabWeb.PageController do
  use PresenceLabWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
