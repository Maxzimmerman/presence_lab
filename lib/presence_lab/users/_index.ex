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

  def create_user(_) do
    Logger.error("username and password required to create user: #{__MODULE__}.create_user/1")

    {:error, :invalid_input}
  end

  def check_password(username, password) do
    with %User{password_hash: hash} = user <- get_user(username),
         {:success, :valid_hash} <- check_hash(password, hash) do
      {:valid, user}
    end
  end

  def get_user(username) do
    Repo.get_by(User, username: username)
  end

  def check_hash(password, hash) do
    case Bcrypt.verify_pass(password, hash) do
      false ->
        {:error, :invalid_hash}

      true ->
        {:success, :valid_hash}
    end
  end
end
