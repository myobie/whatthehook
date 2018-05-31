defmodule WTH.Repo.Migrations.CreateWTH.Webhooks.HookAndHookState do
  use Ecto.Migration

  def change do
    create table(:hooks) do
      add :code, :text, default: "request() { return 0 }", null: false

      timestamps()
    end

    create table(:hook_states) do
      add :hook_id, references(:hooks), null: false
      add :uuid, :string, null: false
      add :value, :map, default: %{}, null: false

      timestamps()
    end

    create index(:hook_states, [:hook_id, :uuid])
  end
end
