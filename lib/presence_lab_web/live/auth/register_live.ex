defmodule PresenceLabWeb.AuthLive do
  use PresenceLabWeb, :live_view

  alias Users.User

  def mount(_params, _session, socket) do
    IO.puts(socket.assigns["user_id"])
    {:ok, assign(socket, form: to_form(User.changeset(%User{}, %{})))}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    form =
      %User{}
      |> User.changeset(user_params)
      |> to_form(action: :validate)

    IO.inspect(socket.assigns.user_id, limit: :infinity)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("register", %{"user" => %{"username" => name, "password" => password}}, socket) do
    case Users.create_user(%{username: name, password: password}) do
      {:ok, %User{id: id}} ->
        {:noreply,
         assign(socket, user_id: id)
         |> put_flash(:info, "user created")
         |> redirect(to: ~p"/")}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "#{inspect(reason)}")
         |> redirect(to: ~p"/")}
    end
  end

  def render(assigns) do
    ~H"""
    HELLO
    <.form for={@form} phx-change="validate" phx-submit="register">
      <.input type="text" field={@form[:username]} />
      <.input type="password" field={@form[:password]} />
      <button>Register</button>
    </.form>
    """
  end
end
