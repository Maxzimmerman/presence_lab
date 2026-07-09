defmodule Users do
  require Logger

  alias PresenceLab.Repo
  alias Users.User

  def create_user(%{username: username, password: password}) do
    hash = Bcrypt.hash_pwd_salt(password)
    params = %{username: username, password_hash: hash}

    User.changeset(%User{}, params)
    |> Repo.insert()
  end
end
