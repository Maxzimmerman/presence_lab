defmodule PresenceLab.Repo do
  use Ecto.Repo,
    otp_app: :presence_lab,
    adapter: Ecto.Adapters.Postgres
end
