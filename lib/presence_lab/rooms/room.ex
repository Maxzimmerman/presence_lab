defmodule PresenceLab.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset

  alias Users.User

  schema "rooms" do
    many_to_many :users, User, join_through: "room_memberships"

    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> cast_assoc(:users)
  end
end
