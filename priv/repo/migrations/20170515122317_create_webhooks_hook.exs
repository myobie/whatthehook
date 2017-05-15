defmodule Whathook.Repo.Migrations.CreateWhathook.Webhooks.Hook do
  use Ecto.Migration

  def change do
    create table(:hooks) do
      add :endpoint, :string
      add :code, :text

      timestamps()
    end
  end
end
