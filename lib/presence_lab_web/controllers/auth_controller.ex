defmodule PresenceLabWeb.AuthController do
  use PresenceLabWeb, :controller

  alias Users.User

  def register(conn, _params) do
    changeset = User.changeset(%User{}, %{})
    render(conn, :register, changeset: changeset)
  end
end
