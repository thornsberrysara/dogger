defmodule DoggerWeb.BusinessConfirmationController do
  use DoggerWeb, :controller

  alias Dogger.Businesses

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"business" => %{"email" => email}}) do
    if business = Businesses.get_business_by_email(email) do
      Businesses.deliver_business_confirmation_instructions(
        business,
        &Routes.business_confirmation_url(conn, :edit, &1)
      )
    end

    # In order to prevent user enumeration attacks, regardless of the outcome, show an impartial success/error message.
    conn
    |> put_flash(
      :info,
      "If your email is in our system and it has not been confirmed yet, " <>
        "you will receive an email with instructions shortly."
    )
    |> redirect(to: "/")
  end

  def edit(conn, %{"token" => token}) do
    render(conn, "edit.html", token: token)
  end

  # Do not log in the business after confirmation to avoid a
  # leaked token giving the business access to the account.
  def update(conn, %{"token" => token}) do
    case Businesses.confirm_business(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Business confirmed successfully.")
        |> redirect(to: "/")

      :error ->
        # If there is a current business and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the business themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          %{current_business: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: "/")

          %{} ->
            conn
            |> put_flash(:error, "Business confirmation link is invalid or it has expired.")
            |> redirect(to: "/")
        end
    end
  end
end
