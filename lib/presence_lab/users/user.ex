defmodule Users.User do
  use Ecto.Schema

  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :password_hash, :string
  end

  @required [
    :username,
    :password_hash
  ]

  def changeset(user, opts) do
    user
    |> cast(opts, @required)
    |> validate_required(@required)
  end
end
