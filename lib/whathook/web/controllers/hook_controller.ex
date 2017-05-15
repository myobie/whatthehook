defmodule Whathook.Web.HookController do
  use Whathook.Web, :controller

  alias Whathook.Webhooks
  alias Whathook.Webhooks.Hook

  action_fallback Whathook.Web.FallbackController

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
end
