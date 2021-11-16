defmodule DoggerWeb.StayController do
  use DoggerWeb, :controller

  alias Dogger.Stays
  alias Dogger.Stays.Stay

  def index(conn, _params) do
    stays = Stays.list_stays()
    render(conn, "index.html", stays: stays)
  end

  def new(conn, _params) do
    changeset = Stays.change_stay(%Stay{})
    pets = Dogger.Pets.list_pets()
    render(conn, "new.html", changeset: changeset, pets: pets)
  end

  def create(conn, %{"stay" => stay_params}) do
    case Stays.create_stay(stay_params) do
      {:ok, stay} ->
        conn
        |> put_flash(:info, "Stay created successfully.")
        |> redirect(to: Routes.stay_path(conn, :show, stay))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    stay = Stays.get_stay!(id)
    owner = Dogger.Owners.get_owner!(id)
    render(conn, "show.html", stay: stay, owner: owner)
  end

  def edit(conn, %{"id" => id}) do
    stay = Stays.get_stay!(id)
    pets = Dogger.Pets.list_pets()
    changeset = Stays.change_stay(stay)
    render(conn, "edit.html", stay: stay, changeset: changeset, pets: pets)
  end

  def update(conn, %{"id" => id, "stay" => stay_params}) do
    stay = Stays.get_stay!(id)

    case Stays.update_stay(stay, stay_params) do
      {:ok, stay} ->
        conn
        |> put_flash(:info, "Stay updated successfully.")
        |> redirect(to: Routes.stay_path(conn, :show, stay))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", stay: stay, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    stay = Stays.get_stay!(id)
    {:ok, _stay} = Stays.delete_stay(stay)

    conn
    |> put_flash(:info, "Stay deleted successfully.")
    |> redirect(to: Routes.stay_path(conn, :index))
  end
end
