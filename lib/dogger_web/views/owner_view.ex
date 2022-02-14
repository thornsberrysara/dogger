defmodule DoggerWeb.OwnerView do
  use DoggerWeb, :view

  def format_phone_number(phone_number) do
    area_code_string = String.slice(phone_number, 0..2)
    exchange_code_string = String.slice(phone_number, 3..5)
    subscriber_number_string = String.slice(phone_number, 6..9)
    "(#{area_code_string}) #{exchange_code_string}-#{subscriber_number_string}"
  end

  def capitalize_first_name(first_name) do
    capital_first_name = String.capitalize(first_name)
    "#{capital_first_name}"
  end

  def capitalize_last_name(last_name) do
    capital_last_name = String.capitalize(last_name)
    "#{capital_last_name}"
  end
end
