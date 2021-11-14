defmodule Dogger.Stays do
  @moduledoc """
  The Stays context.
  """

  import Ecto.Query, warn: false
  alias Dogger.Repo

  alias Dogger.Stays.Stay

  @doc """
  Returns the list of stays.

  ## Examples

      iex> list_stays()
      [%Stay{}, ...]

  """
  def list_stays do
    Repo.all(Stay)
    |> Repo.preload(:pet)
  end

  @doc """
  Gets a single stay.

  Raises `Ecto.NoResultsError` if the Stay does not exist.

  ## Examples

      iex> get_stay!(123)
      %Stay{}

      iex> get_stay!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stay!(id) do
    Repo.get!(Stay, id)
    |> Repo.preload(:pet)
  end

  @doc """
  Creates a stay.

  ## Examples

      iex> create_stay(%{field: value})
      {:ok, %Stay{}}

      iex> create_stay(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_stay(attrs \\ %{}) do
    %Stay{}
    |> Stay.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a stay.

  ## Examples

      iex> update_stay(stay, %{field: new_value})
      {:ok, %Stay{}}

      iex> update_stay(stay, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_stay(%Stay{} = stay, attrs) do
    stay
    |> Stay.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a stay.

  ## Examples

      iex> delete_stay(stay)
      {:ok, %Stay{}}

      iex> delete_stay(stay)
      {:error, %Ecto.Changeset{}}

  """
  def delete_stay(%Stay{} = stay) do
    Repo.delete(stay)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stay changes.

  ## Examples

      iex> change_stay(stay)
      %Ecto.Changeset{data: %Stay{}}

  """
  def change_stay(%Stay{} = stay, attrs \\ %{}) do
    Stay.changeset(stay, attrs)
  end
end
