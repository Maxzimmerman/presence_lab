defmodule PresenceLab.RoomMemberships do
  alias PresenceLab.Repo
  alias PresenceLab.RoomMemberships.RoomMembership
  alias PresenceLab.Rooms.Room
  alias Users.User

  def join(%Room{id: room_id}, %User{id: user_id}) do
    %RoomMembership{}
    |> RoomMembership.changeset(%{room_id: room_id, user_id: user_id})
    |> Repo.insert()
  end

  def leave(%Room{id: room_id}, %User{id: user_id}) do
    with %RoomMembership{} = rm <- get_room_membership(room_id, user_id),
         {:ok, deleted_rm} <- Repo.delete(rm) do
      {:deleted, deleted_rm}
    end
  end

  defp get_room_membership(room_id, user_id) do
    Repo.get_by(RoomMembership, room_id: room_id, user_id: user_id)
  end
end
