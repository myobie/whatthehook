defmodule WTH.Webhooks do
  @moduledoc false

  alias WTH.Repo
  alias WTH.Webhooks.Hook

  @type not_found_error :: {:error, :not_found}
  @type changeset_error :: {:error, Ecto.Changeset.t}

  @spec get_hook(binary | integer) :: Hook.t | not_found_error | no_return
  def get_hook(id) do
    case Repo.get(Hook, id) do
      nil -> {:error, :not_found}
      hook -> {:ok, hook}
    end
  end

  @spec create_hook(map) :: {:ok, Hook.t} | changeset_error
  def create_hook(attrs) do
    %Hook{}
    |> Hook.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_hook(Hook.t, map) :: {:ok, Hook.t} | changeset_error
  def update_hook(%Hook{} = hook, attrs) do
    hook
    |> Hook.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_hook(Hook.t) :: {:ok, Hook.t} | changeset_error
  def delete_hook(%Hook{} = hook) do
    Repo.delete(hook)
  end

  def execute_hook(%Hook{} = hook, state_id, request_info) do
    WTH.Webhooks.Supervisor.execute(hook, state_id, request_info)
  end
end
