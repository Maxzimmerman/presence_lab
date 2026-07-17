defmodule PresenceLab.Repo.Migrations.CreateRoomMemberships do
  use Ecto.Migration

  def change do
    create table(:room_memberships, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), primary_key: true
      add :room_id, references(:rooms, on_delete: :delete_all), primary_key: true
    end

    create unique_index(:room_memberships, [:user_id, :room_id])
  end
end
