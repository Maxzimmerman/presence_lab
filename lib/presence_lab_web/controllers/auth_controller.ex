defmodule PresenceLabWeb.AuthController do
  use PresenceLabWeb, :controller

  alias Users
  alias Users.User

  def register(conn, _params) do
    changeset = User.changeset(%User{}, %{})
    render(conn, :register, changeset: changeset)
  end

  def create_user(conn, %{"user" => user}) do
    IO.inspect(user)

    case Users.create_user(%{username: user["username"], password: user["password"]}) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome on board #{user.username}")
        |> redirect(to: ~p"/")

      {:error, reason} ->
        conn
        |> put_flash(:error, "#{inspect(reason)}")
        |> redirect(to: ~p"/")
    end
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "Logged out")
    |> redirect(to: ~p"/")
  end
end
