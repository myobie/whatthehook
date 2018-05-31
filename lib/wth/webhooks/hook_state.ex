defmodule WTH.Webhooks.HookState do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias WTH.Webhooks.Hook

  @type t :: %__MODULE__{}

  schema "hook_states" do
    belongs_to :hook, Hook

    field :uuid, :string
    field :value, :map, default: %{}

    timestamps()
  end

  @required_attrs [:uuid]
  @optional_attrs [:value]

  @spec changeset(t | Ecto.Changeset.t, map) :: Ecto.Changeset.t
  @spec changeset(t | Ecto.Changeset.t, map, hook: Hook.t) :: Ecto.Changeset.t

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  def changeset(struct, attrs, hook: hook) do
    struct
    |> changeset(attrs)
    |> put_assoc(:hook, hook)
  end
end
