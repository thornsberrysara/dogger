defmodule DoggerWeb.PetView do
  use DoggerWeb, :view

  def capitalize_name(name) do
    capital_name = String.capitalize(name)
    "#{capital_name}"
  end

  def capitalize_owner_first_name(first_name) do
    capital_first_name = String.capitalize(first_name)
    "#{capital_first_name}"
  end

  def capitalize_owner_last_name(last_name) do
    capital_last_name = String.capitalize(last_name)
    "#{capital_last_name}"
  end
end
