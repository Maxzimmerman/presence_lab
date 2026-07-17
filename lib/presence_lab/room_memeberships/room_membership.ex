defmodule PresenceLab.RoomMemeberships.RoomMembership do
  use Ecto.Schema
  import Ecto.Changeset

  alias Users.User
  alias PresenceLab.Rooms.Room

  schema "room_memberships" do
    belongs_to :room, Room
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @required [
    :room_id,
    :user_id
  ]

  @optional []

  @doc false
  def changeset(room_membership, attrs) do
    room_membership
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> foreign_key_constraint(:room_id)
    |> foreign_key_constraint(:user_id)
  end
end
