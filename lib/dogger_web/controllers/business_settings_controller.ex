defmodule DoggerWeb.BusinessSettingsController do
  use DoggerWeb, :controller

  alias Dogger.Businesses
  alias DoggerWeb.BusinessAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "business" => business_params} = params
    business = conn.assigns.current_business

    case Businesses.apply_business_email(business, password, business_params) do
      {:ok, applied_business} ->
        Businesses.deliver_update_email_instructions(
          applied_business,
          business.email,
          &Routes.business_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: Routes.business_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "business" => business_params} = params
    business = conn.assigns.current_business

    case Businesses.update_business_password(business, password, business_params) do
      {:ok, business} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:business_return_to, Routes.business_settings_path(conn, :edit))
        |> BusinessAuth.log_in_business(business)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Businesses.update_business_email(conn.assigns.current_business, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: Routes.business_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: Routes.business_settings_path(conn, :edit))
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    business = conn.assigns.current_business

    conn
    |> assign(:email_changeset, Businesses.change_business_email(business))
    |> assign(:password_changeset, Businesses.change_business_password(business))
  end
end
