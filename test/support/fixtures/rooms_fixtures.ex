defmodule PresenceLab.RoomsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PresenceLab.Rooms` context.
  """

  @doc """
  Generate a room.
  """
  def room_fixture(attrs \\ %{}) do
    {:ok, room} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> PresenceLab.Rooms.create_room()

    room
  end
end
