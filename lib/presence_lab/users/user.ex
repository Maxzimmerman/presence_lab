defmodule Users.User do
  use Ecto.Schema

  import Ecto.Changeset

  alias PresenceLab.Rooms.Room

  schema "users" do
    many_to_many :rooms, Room, join_through: "room_memberships"

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
    |> unique_constraint(:username)
    |> cast_assoc(:rooms)
  end
end
