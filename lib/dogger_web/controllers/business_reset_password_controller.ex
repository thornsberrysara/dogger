defmodule DoggerWeb.BusinessResetPasswordController do
  use DoggerWeb, :controller

  alias Dogger.Businesses

  plug :get_business_by_reset_password_token when action in [:edit, :update]

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"business" => %{"email" => email}}) do
    if business = Businesses.get_business_by_email(email) do
      Businesses.deliver_business_reset_password_instructions(
        business,
        &Routes.business_reset_password_url(conn, :edit, &1)
      )
    end

    # In order to prevent user enumeration attacks, regardless of the outcome, show an impartial success/error message.
    conn
    |> put_flash(
      :info,
      "If your email is in our system, you will receive instructions to reset your password shortly."
    )
    |> redirect(to: "/")
  end

  def edit(conn, _params) do
    render(conn, "edit.html", changeset: Businesses.change_business_password(conn.assigns.business))
  end

  # Do not log in the business after reset password to avoid a
  # leaked token giving the business access to the account.
  def update(conn, %{"business" => business_params}) do
    case Businesses.reset_business_password(conn.assigns.business, business_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password reset successfully.")
        |> redirect(to: Routes.business_session_path(conn, :new))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  defp get_business_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if business = Businesses.get_business_by_reset_password_token(token) do
      conn |> assign(:business, business) |> assign(:token, token)
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
