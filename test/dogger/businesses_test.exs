defmodule Dogger.BusinessesTest do
  use Dogger.DataCase

  alias Dogger.Businesses

  import Dogger.BusinessesFixtures
  alias Dogger.Businesses.{Business, BusinessToken}

  describe "get_business_by_email/1" do
    test "does not return the business if the email does not exist" do
      refute Businesses.get_business_by_email("unknown@example.com")
    end

    test "returns the business if the email exists" do
      %{id: id} = business = business_fixture()
      assert %Business{id: ^id} = Businesses.get_business_by_email(business.email)
    end
  end

  describe "get_business_by_email_and_password/2" do
    test "does not return the business if the email does not exist" do
      refute Businesses.get_business_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the business if the password is not valid" do
      business = business_fixture()
      refute Businesses.get_business_by_email_and_password(business.email, "invalid")
    end

    test "returns the business if the email and password are valid" do
      %{id: id} = business = business_fixture()

      assert %Business{id: ^id} =
               Businesses.get_business_by_email_and_password(business.email, valid_business_password())
    end
  end

  describe "get_business!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Businesses.get_business!(-1)
      end
    end

    test "returns the business with the given id" do
      %{id: id} = business = business_fixture()
      assert %Business{id: ^id} = Businesses.get_business!(business.id)
    end
  end

  describe "register_business/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Businesses.register_business(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Businesses.register_business(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Businesses.register_business(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = business_fixture()
      {:error, changeset} = Businesses.register_business(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Businesses.register_business(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers businesses with a hashed password" do
      email = unique_business_email()
      {:ok, business} = Businesses.register_business(valid_business_attributes(email: email))
      assert business.email == email
      assert is_binary(business.hashed_password)
      assert is_nil(business.confirmed_at)
      assert is_nil(business.password)
    end
  end

  describe "change_business_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Businesses.change_business_registration(%Business{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_business_email()
      password = valid_business_password()

      changeset =
        Businesses.change_business_registration(
          %Business{},
          valid_business_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_business_email/2" do
    test "returns a business changeset" do
      assert %Ecto.Changeset{} = changeset = Businesses.change_business_email(%Business{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_business_email/3" do
    setup do
      %{business: business_fixture()}
    end

    test "requires email to change", %{business: business} do
      {:error, changeset} = Businesses.apply_business_email(business, valid_business_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{business: business} do
      {:error, changeset} =
        Businesses.apply_business_email(business, valid_business_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{business: business} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Businesses.apply_business_email(business, valid_business_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{business: business} do
      %{email: email} = business_fixture()

      {:error, changeset} =
        Businesses.apply_business_email(business, valid_business_password(), %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{business: business} do
      {:error, changeset} =
        Businesses.apply_business_email(business, "invalid", %{email: unique_business_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{business: business} do
      email = unique_business_email()
      {:ok, business} = Businesses.apply_business_email(business, valid_business_password(), %{email: email})
      assert business.email == email
      assert Businesses.get_business!(business.id).email != email
    end
  end

  describe "deliver_update_email_instructions/3" do
    setup do
      %{business: business_fixture()}
    end

    test "sends token through notification", %{business: business} do
      token =
        extract_business_token(fn url ->
          Businesses.deliver_update_email_instructions(business, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert business_token = Repo.get_by(BusinessToken, token: :crypto.hash(:sha256, token))
      assert business_token.business_id == business.id
      assert business_token.sent_to == business.email
      assert business_token.context == "change:current@example.com"
    end
  end

  describe "update_business_email/2" do
    setup do
      business = business_fixture()
      email = unique_business_email()

      token =
        extract_business_token(fn url ->
          Businesses.deliver_update_email_instructions(%{business | email: email}, business.email, url)
        end)

      %{business: business, token: token, email: email}
    end

    test "updates the email with a valid token", %{business: business, token: token, email: email} do
      assert Businesses.update_business_email(business, token) == :ok
      changed_business = Repo.get!(Business, business.id)
      assert changed_business.email != business.email
      assert changed_business.email == email
      assert changed_business.confirmed_at
      assert changed_business.confirmed_at != business.confirmed_at
      refute Repo.get_by(BusinessToken, business_id: business.id)
    end

    test "does not update email with invalid token", %{business: business} do
      assert Businesses.update_business_email(business, "oops") == :error
      assert Repo.get!(Business, business.id).email == business.email
      assert Repo.get_by(BusinessToken, business_id: business.id)
    end

    test "does not update email if business email changed", %{business: business, token: token} do
      assert Businesses.update_business_email(%{business | email: "current@example.com"}, token) == :error
      assert Repo.get!(Business, business.id).email == business.email
      assert Repo.get_by(BusinessToken, business_id: business.id)
    end

    test "does not update email if token expired", %{business: business, token: token} do
      {1, nil} = Repo.update_all(BusinessToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Businesses.update_business_email(business, token) == :error
      assert Repo.get!(Business, business.id).email == business.email
      assert Repo.get_by(BusinessToken, business_id: business.id)
    end
  end

  describe "change_business_password/2" do
    test "returns a business changeset" do
      assert %Ecto.Changeset{} = changeset = Businesses.change_business_password(%Business{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Businesses.change_business_password(%Business{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_business_password/3" do
    setup do
      %{business: business_fixture()}
    end

    test "validates password", %{business: business} do
      {:error, changeset} =
        Businesses.update_business_password(business, valid_business_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{business: business} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Businesses.update_business_password(business, valid_business_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{business: business} do
      {:error, changeset} =
        Businesses.update_business_password(business, "invalid", %{password: valid_business_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{business: business} do
      {:ok, business} =
        Businesses.update_business_password(business, valid_business_password(), %{
          password: "new valid password"
        })

      assert is_nil(business.password)
      assert Businesses.get_business_by_email_and_password(business.email, "new valid password")
    end

    test "deletes all tokens for the given business", %{business: business} do
      _ = Businesses.generate_business_session_token(business)

      {:ok, _} =
        Businesses.update_business_password(business, valid_business_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(BusinessToken, business_id: business.id)
    end
  end

  describe "generate_business_session_token/1" do
    setup do
      %{business: business_fixture()}
    end

    test "generates a token", %{business: business} do
      token = Businesses.generate_business_session_token(business)
      assert business_token = Repo.get_by(BusinessToken, token: token)
      assert business_token.context == "session"

      # Creating the same token for another business should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%BusinessToken{
          token: business_token.token,
          business_id: business_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_business_by_session_token/1" do
    setup do
      business = business_fixture()
      token = Businesses.generate_business_session_token(business)
      %{business: business, token: token}
    end

    test "returns business by token", %{business: business, token: token} do
      assert session_business = Businesses.get_business_by_session_token(token)
      assert session_business.id == business.id
    end

    test "does not return business for invalid token" do
      refute Businesses.get_business_by_session_token("oops")
    end

    test "does not return business for expired token", %{token: token} do
      {1, nil} = Repo.update_all(BusinessToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Businesses.get_business_by_session_token(token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      business = business_fixture()
      token = Businesses.generate_business_session_token(business)
      assert Businesses.delete_session_token(token) == :ok
      refute Businesses.get_business_by_session_token(token)
    end
  end

  describe "deliver_business_confirmation_instructions/2" do
    setup do
      %{business: business_fixture()}
    end

    test "sends token through notification", %{business: business} do
      token =
        extract_business_token(fn url ->
          Businesses.deliver_business_confirmation_instructions(business, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert business_token = Repo.get_by(BusinessToken, token: :crypto.hash(:sha256, token))
      assert business_token.business_id == business.id
      assert business_token.sent_to == business.email
      assert business_token.context == "confirm"
    end
  end

  describe "confirm_business/1" do
    setup do
      business = business_fixture()

      token =
        extract_business_token(fn url ->
          Businesses.deliver_business_confirmation_instructions(business, url)
        end)

      %{business: business, token: token}
    end

    test "confirms the email with a valid token", %{business: business, token: token} do
      assert {:ok, confirmed_business} = Businesses.confirm_business(token)
      assert confirmed_business.confirmed_at
      assert confirmed_business.confirmed_at != business.confirmed_at
      assert Repo.get!(Business, business.id).confirmed_at
      refute Repo.get_by(BusinessToken, business_id: business.id)
    end

    test "does not confirm with invalid token", %{business: business} do
      assert Businesses.confirm_business("oops") == :error
      refute Repo.get!(Business, business.id).confirmed_at
      assert Repo.get_by(BusinessToken, business_id: business.id)
    end

    test "does not confirm email if token expired", %{business: business, token: token} do
      {1, nil} = Repo.update_all(BusinessToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Businesses.confirm_business(token) == :error
      refute Repo.get!(Business, business.id).confirmed_at
      assert Repo.get_by(BusinessToken, business_id: business.id)
    end
  end

  describe "deliver_business_reset_password_instructions/2" do
    setup do
      %{business: business_fixture()}
    end

    test "sends token through notification", %{business: business} do
      token =
        extract_business_token(fn url ->
          Businesses.deliver_business_reset_password_instructions(business, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert business_token = Repo.get_by(BusinessToken, token: :crypto.hash(:sha256, token))
      assert business_token.business_id == business.id
      assert business_token.sent_to == business.email
      assert business_token.context == "reset_password"
    end
  end

  describe "get_business_by_reset_password_token/1" do
    setup do
      business = business_fixture()

      token =
        extract_business_token(fn url ->
          Businesses.deliver_business_reset_password_instructions(business, url)
        end)

      %{business: business, token: token}
    end

    test "returns the business with valid token", %{business: %{id: id}, token: token} do
      assert %Business{id: ^id} = Businesses.get_business_by_reset_password_token(token)
      assert Repo.get_by(BusinessToken, business_id: id)
    end

    test "does not return the business with invalid token", %{business: business} do
      refute Businesses.get_business_by_reset_password_token("oops")
      assert Repo.get_by(BusinessToken, business_id: business.id)
    end

    test "does not return the business if token expired", %{business: business, token: token} do
      {1, nil} = Repo.update_all(BusinessToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Businesses.get_business_by_reset_password_token(token)
      assert Repo.get_by(BusinessToken, business_id: business.id)
    end
  end

  describe "reset_business_password/2" do
    setup do
      %{business: business_fixture()}
    end

    test "validates password", %{business: business} do
      {:error, changeset} =
        Businesses.reset_business_password(business, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{business: business} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Businesses.reset_business_password(business, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{business: business} do
      {:ok, updated_business} = Businesses.reset_business_password(business, %{password: "new valid password"})
      assert is_nil(updated_business.password)
      assert Businesses.get_business_by_email_and_password(business.email, "new valid password")
    end

    test "deletes all tokens for the given business", %{business: business} do
      _ = Businesses.generate_business_session_token(business)
      {:ok, _} = Businesses.reset_business_password(business, %{password: "new valid password"})
      refute Repo.get_by(BusinessToken, business_id: business.id)
    end
  end

  describe "inspect/2" do
    test "does not include password" do
      refute inspect(%Business{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
