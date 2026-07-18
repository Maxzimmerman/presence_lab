defmodule PresenceLab.RoomMemberships do
  import Ecto.Query

  alias PresenceLab.Repo
  alias PresenceLab.RoomMemberships.RoomMembership
  alias PresenceLab.Rooms.Room
  alias Users.User

  def join(%Room{id: room_id}, %User{id: user_id}) do
    %RoomMembership{}
    |> RoomMembership.changeset(%{room_id: room_id, user_id: user_id})
    |> Repo.insert()
  end

  def create_room(%User{id: user_id}, attrs) do
    %Room{}
    |> Room.changeset(Map.put(attrs, :user_id, user_id))
    |> Repo.insert()
  end

  def leave(%Room{id: room_id}, %User{id: user_id}) do
    with %RoomMembership{} = rm <- get_room_membership(room_id, user_id),
         {:ok, deleted_rm} <- Repo.delete(rm) do
      {:deleted, deleted_rm}
    end
  end

  def get_rooms_for_user(%User{id: user_id}) do
    RoomMembership
    |> where([ur], ur.user_id == ^user_id)
    |> join(:inner, [ur], r in Room, on: ur.room_id == r.id)
    |> Repo.all()
  end

  def get_rooms do
    RoomMembership
    |> distinct([ur], ur.room_id)
    |> join(:inner, [ur], r in Room, on: ur.room_id == r.id)
    |> select([ur, r], {r.id, r.name})
    |> Repo.all()
  end

  defp get_room_membership(room_id, user_id) do
    Repo.get_by(RoomMembership, room_id: room_id, user_id: user_id)
  end
end
