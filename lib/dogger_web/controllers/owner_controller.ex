defmodule DoggerWeb.OwnerController do
  use DoggerWeb, :controller

  alias Dogger.Owners
  alias Dogger.Owners.Owner

  def index(conn, _params) do
    owners = Owners.list_owners()
    render(conn, "index.html", owners: owners)
  end

  def new(conn, _params) do
    changeset = Owners.change_owner(%Owner{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"owner" => owner_params}) do
    case Owners.create_owner(owner_params) do
      {:ok, owner} ->
        conn
        |> put_flash(:info, "Owner created successfully.")
        |> redirect(to: Routes.owner_path(conn, :show, owner))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    owner = Owners.get_owner!(id)
    pets = Dogger.Pets.list_pets()
    render(conn, "show.html", owner: owner, pets: pets)
  end

  def edit(conn, %{"id" => id}) do
    owner = Owners.get_owner!(id)
    changeset = Owners.change_owner(owner)
    render(conn, "edit.html", owner: owner, changeset: changeset)
  end

  def update(conn, %{"id" => id, "owner" => owner_params}) do
    owner = Owners.get_owner!(id)

    case Owners.update_owner(owner, owner_params) do
      {:ok, owner} ->
        conn
        |> put_flash(:info, "Owner updated successfully.")
        |> redirect(to: Routes.owner_path(conn, :show, owner))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", owner: owner, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    owner = Owners.get_owner!(id)
    {:ok, _owner} = Owners.delete_owner(owner)

    conn
    |> put_flash(:info, "Owner deleted successfully.")
    |> redirect(to: Routes.owner_path(conn, :index))
  end
end
