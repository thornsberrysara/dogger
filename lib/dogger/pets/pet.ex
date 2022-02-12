defmodule Dogger.Pets.Pet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pets" do
    field :breed, Ecto.Enum,
      values: [
        :Australian_Shepherd,
        :Beagle,
        :Boxer,
        :Bulldog,
        :Corgi,
        :Dachshund,
        :Doberman_Pinscher,
        :German_Shepherd,
        :Golden_Retriever,
        :Great_Dane,
        :Husky,
        :Labrador_Retriever,
        :Pointer,
        :Poodle,
        :Rottweiler,
        :Schnauzer,
        :Shih_Tzu,
        :Yorkie
      ]

    field :dob, :date
    field :medications, :boolean, default: false
    field :name, :string
    field :weight, :integer
    belongs_to :owner, Dogger.Owners.Owner
    has_many :stay, Dogger.Stays.Stay, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(pet, attrs) do
    pet
    |> cast(attrs, [:name, :owner_id, :breed, :dob, :weight, :medications])
    |> cast_assoc(:stay)
    |> validate_required([:name, :owner_id, :breed, :dob, :weight, :medications])
  end
end
