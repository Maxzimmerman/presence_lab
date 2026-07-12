defmodule PresenceLabWeb.Plugs.SetUserPlug do
  import Plug.Conn

  alias Users.User
  alias PresenceLab.Repo

  def init(default), do: default

  def call(%Plug.Conn{} = conn, _default) do
    user_id = get_session(conn)["user_id"]

    cond do
      user = user_id && Repo.get(User, user_id) ->
        assign(conn, :user, user)

      true ->
        assign(conn, :user, nil)
    end
  end
end
