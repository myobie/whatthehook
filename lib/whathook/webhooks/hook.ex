defmodule Whathook.Webhooks.Hook do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "hooks" do
    field :code, :string
    field :endpoint, :string

    timestamps()
  end

  @required_attrs []
  @optional_attrs [:endpoint, :code]

  @spec changeset(t | Ecto.Changeset.t, map) :: Ecto.Changeset.t
  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:token)
  end
end
