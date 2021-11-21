defmodule Dogger.Businesses do
  @moduledoc """
  The Businesses context.
  """

  import Ecto.Query, warn: false
  alias Dogger.Repo

  alias Dogger.Businesses.{Business, BusinessToken, BusinessNotifier}

  ## Database getters

  @doc """
  Gets a business by email.

  ## Examples

      iex> get_business_by_email("foo@example.com")
      %Business{}

      iex> get_business_by_email("unknown@example.com")
      nil

  """
  def get_business_by_email(email) when is_binary(email) do
    Repo.get_by(Business, email: email)
  end

  @doc """
  Gets a business by email and password.

  ## Examples

      iex> get_business_by_email_and_password("foo@example.com", "correct_password")
      %Business{}

      iex> get_business_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_business_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    business = Repo.get_by(Business, email: email)
    if Business.valid_password?(business, password), do: business
  end

  @doc """
  Gets a single business.

  Raises `Ecto.NoResultsError` if the Business does not exist.

  ## Examples

      iex> get_business!(123)
      %Business{}

      iex> get_business!(456)
      ** (Ecto.NoResultsError)

  """
  def get_business!(id), do: Repo.get!(Business, id)

  ## Business registration

  @doc """
  Registers a business.

  ## Examples

      iex> register_business(%{field: value})
      {:ok, %Business{}}

      iex> register_business(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_business(attrs) do
    %Business{}
    |> Business.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking business changes.

  ## Examples

      iex> change_business_registration(business)
      %Ecto.Changeset{data: %Business{}}

  """
  def change_business_registration(%Business{} = business, attrs \\ %{}) do
    Business.registration_changeset(business, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the business email.

  ## Examples

      iex> change_business_email(business)
      %Ecto.Changeset{data: %Business{}}

  """
  def change_business_email(business, attrs \\ %{}) do
    Business.email_changeset(business, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_business_email(business, "valid password", %{email: ...})
      {:ok, %Business{}}

      iex> apply_business_email(business, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_business_email(business, password, attrs) do
    business
    |> Business.email_changeset(attrs)
    |> Business.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the business email using the given token.

  If the token matches, the business email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_business_email(business, token) do
    context = "change:#{business.email}"

    with {:ok, query} <- BusinessToken.verify_change_email_token_query(token, context),
         %BusinessToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(business_email_multi(business, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp business_email_multi(business, email, context) do
    changeset = business |> Business.email_changeset(%{email: email}) |> Business.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:business, changeset)
    |> Ecto.Multi.delete_all(:tokens, BusinessToken.business_and_contexts_query(business, [context]))
  end

  @doc """
  Delivers the update email instructions to the given business.

  ## Examples

      iex> deliver_update_email_instructions(business, current_email, &Routes.business_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(%Business{} = business, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, business_token} = BusinessToken.build_email_token(business, "change:#{current_email}")

    Repo.insert!(business_token)
    BusinessNotifier.deliver_update_email_instructions(business, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the business password.

  ## Examples

      iex> change_business_password(business)
      %Ecto.Changeset{data: %Business{}}

  """
  def change_business_password(business, attrs \\ %{}) do
    Business.password_changeset(business, attrs, hash_password: false)
  end

  @doc """
  Updates the business password.

  ## Examples

      iex> update_business_password(business, "valid password", %{password: ...})
      {:ok, %Business{}}

      iex> update_business_password(business, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_business_password(business, password, attrs) do
    changeset =
      business
      |> Business.password_changeset(attrs)
      |> Business.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:business, changeset)
    |> Ecto.Multi.delete_all(:tokens, BusinessToken.business_and_contexts_query(business, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{business: business}} -> {:ok, business}
      {:error, :business, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_business_session_token(business) do
    {token, business_token} = BusinessToken.build_session_token(business)
    Repo.insert!(business_token)
    token
  end

  @doc """
  Gets the business with the given signed token.
  """
  def get_business_by_session_token(token) do
    {:ok, query} = BusinessToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(BusinessToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given business.

  ## Examples

      iex> deliver_business_confirmation_instructions(business, &Routes.business_confirmation_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_business_confirmation_instructions(confirmed_business, &Routes.business_confirmation_url(conn, :edit, &1))
      {:error, :already_confirmed}

  """
  def deliver_business_confirmation_instructions(%Business{} = business, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if business.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, business_token} = BusinessToken.build_email_token(business, "confirm")
      Repo.insert!(business_token)
      BusinessNotifier.deliver_confirmation_instructions(business, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a business by the given token.

  If the token matches, the business account is marked as confirmed
  and the token is deleted.
  """
  def confirm_business(token) do
    with {:ok, query} <- BusinessToken.verify_email_token_query(token, "confirm"),
         %Business{} = business <- Repo.one(query),
         {:ok, %{business: business}} <- Repo.transaction(confirm_business_multi(business)) do
      {:ok, business}
    else
      _ -> :error
    end
  end

  defp confirm_business_multi(business) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:business, Business.confirm_changeset(business))
    |> Ecto.Multi.delete_all(:tokens, BusinessToken.business_and_contexts_query(business, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given business.

  ## Examples

      iex> deliver_business_reset_password_instructions(business, &Routes.business_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_business_reset_password_instructions(%Business{} = business, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, business_token} = BusinessToken.build_email_token(business, "reset_password")
    Repo.insert!(business_token)
    BusinessNotifier.deliver_reset_password_instructions(business, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the business by reset password token.

  ## Examples

      iex> get_business_by_reset_password_token("validtoken")
      %Business{}

      iex> get_business_by_reset_password_token("invalidtoken")
      nil

  """
  def get_business_by_reset_password_token(token) do
    with {:ok, query} <- BusinessToken.verify_email_token_query(token, "reset_password"),
         %Business{} = business <- Repo.one(query) do
      business
    else
      _ -> nil
    end
  end

  @doc """
  Resets the business password.

  ## Examples

      iex> reset_business_password(business, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Business{}}

      iex> reset_business_password(business, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_business_password(business, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:business, Business.password_changeset(business, attrs))
    |> Ecto.Multi.delete_all(:tokens, BusinessToken.business_and_contexts_query(business, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{business: business}} -> {:ok, business}
      {:error, :business, changeset, _} -> {:error, changeset}
    end
  end
end
