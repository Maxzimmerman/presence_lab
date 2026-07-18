defmodule PresenceLabWeb.RoomsLive do
  use Phoenix.LiveView

  def mount(params, session, socket) do
    {:ok, assign(socket, rooms: [])}
  end

  def render(assigns) do
    ~H"""
    Rooms
    """
  end
end
