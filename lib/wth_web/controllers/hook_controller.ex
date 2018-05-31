defmodule WTHWeb.HookController do
  require Logger
  use WTHWeb, :controller

  alias WTH.Webhooks
  alias WTH.Webhooks.Hook

  action_fallback WTHWeb.FallbackController

  def create(conn, params) do
    with {:ok, %Hook{} = hook} <- Webhooks.create_hook(params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", hook_path(conn, :show, hook))
      |> render("show.json", hook: hook)
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, %Hook{} = hook} <- Webhooks.get_hook(id) do
      render(conn, "show.json", hook: hook)
    end
  end

  def update(conn, %{"id" => id} = params) do
    with {:ok, %Hook{} = hook} <- Webhooks.get_hook(id),
         {:ok, %Hook{} = hook} <- Webhooks.update_hook(hook, params) do
      render(conn, "show.json", hook: hook)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, %Hook{} = hook} <- Webhooks.get_hook(id),
         {:ok, %Hook{}} <- Webhooks.delete_hook(hook) do
      send_resp(conn, :no_content, "")
    end
  end

  @fake_body %{"fake" => "data"}

  def execute(conn, %{"id" => id, "state_id" => state_id}) do
    with {:ok, %Hook{} = hook} <- Webhooks.get_hook(id) do
      case Webhooks.execute_hook(hook, state_id, %{body: @fake_body}) do
        {:ok, result} ->
          status = Map.get(result, "status", 200)
          body = Map.get(result, "body", "")
          state = Poison.encode!(Map.get(result, "state", %{}))

          conn
          |> put_resp_header("X-Hook-State", state)
          |> send_resp(status, body)
        other ->
          Logger.debug(inspect(other))
          send_resp(conn, 500, "ooooooh snap you broke it!")
      end
    end
  end
end
