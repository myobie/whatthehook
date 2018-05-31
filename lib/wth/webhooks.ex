defmodule WTH.Webhooks do
  @moduledoc false

  alias WTH.Repo
  alias WTH.Webhooks.{Hook, HookState}

  @type not_found_error :: {:error, :not_found}
  @type changeset_error :: {:error, Ecto.Changeset.t}

  @spec get_hook(binary | integer) :: {:ok, Hook.t} | not_found_error
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
  def update_hook(hook, attrs) do
    hook
    |> Hook.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_hook(Hook.t) :: {:ok, Hook.t} | changeset_error
  def delete_hook(hook) do
    Repo.delete(hook)
  end

  @spec execute_hook(Hook.t, binary, map) :: {:ok, map} | {:error, term}
  def execute_hook(hook, state_id, request_info) do
    WTH.Webhooks.Supervisor.execute(hook, state_id, request_info)
  end

  @spec get_hook_state(binary | integer, binary) :: {:ok, HookState.t} | not_found_error
  def get_hook_state(hook_id, uuid) do
    case Repo.get_by(HookState, hook_id: hook_id, uuid: uuid) do
      nil -> {:error, :not_found}
      state -> {:ok, state}
    end
  end

  @spec create_hook_state(map, hook: Hook.t) :: {:ok, HookState.t} | changeset_error
  def create_hook_state(attrs, hook: hook) do
    %HookState{}
    |> HookState.changeset(attrs, hook: hook)
    |> Repo.insert()
  end

  @spec get_or_create_hook_state(binary | integer, binary) :: {:ok, HookState.t} | not_found_error
  def get_or_create_hook_state(hook_id, uuid) do
    # FIXME: This is naive and should instead use the conflict options
    with {:ok, hook} <- get_hook(hook_id),
         {:error, :not_found} <- get_hook_state(hook.id, uuid) do
      create_hook_state(%{uuid: uuid}, hook: hook)
    end
  end

  @spec update_hook_state(HookState.t, map) :: {:ok, HookState.t} | changeset_error
  def update_hook_state(hook_state, attrs) do
    hook_state
    |> HookState.changeset(attrs)
    |> Repo.update()
  end
end
