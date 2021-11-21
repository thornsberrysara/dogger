defmodule DoggerWeb.BusinessRegistrationController do
  use DoggerWeb, :controller

  alias Dogger.Businesses
  alias Dogger.Businesses.Business
  alias DoggerWeb.BusinessAuth

  def new(conn, _params) do
    changeset = Businesses.change_business_registration(%Business{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"business" => business_params}) do
    case Businesses.register_business(business_params) do
      {:ok, business} ->
        {:ok, _} =
          Businesses.deliver_business_confirmation_instructions(
            business,
            &Routes.business_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, "Business created successfully.")
        |> BusinessAuth.log_in_business(business)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
