defmodule Dogger.BusinessesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Dogger.Businesses` context.
  """

  def unique_business_email, do: "business#{System.unique_integer()}@example.com"
  def valid_business_password, do: "hello world!"

  def valid_business_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_business_email(),
      password: valid_business_password()
    })
  end

  def business_fixture(attrs \\ %{}) do
    {:ok, business} =
      attrs
      |> valid_business_attributes()
      |> Dogger.Businesses.register_business()

    business
  end

  def extract_business_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
