defmodule DoggerWeb.BusinessSessionController do
  use DoggerWeb, :controller

  alias Dogger.Businesses
  alias DoggerWeb.BusinessAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"business" => business_params}) do
    %{"email" => email, "password" => password} = business_params

    if business = Businesses.get_business_by_email_and_password(email, password) do
      BusinessAuth.log_in_business(conn, business, business_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, "new.html", error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> BusinessAuth.log_out_business()
  end
end
