defmodule WTH.WebhooksTest do
  use WTH.DataCase

  alias WTH.Webhooks
  alias WTH.Webhooks.Hook

  test "get_hook returns the hook with given id" do
    hook = insert(:hook)
    assert Webhooks.get_hook(hook.id) == {:ok, hook}
  end

  test "create_hook/1 with valid data creates a hook" do
    assert {:ok, %Hook{}} = Webhooks.create_hook(params_for(:hook))
  end

  test "update_hook/2 with valid data updates the hook" do
    hook = insert(:hook)
    assert {:ok, %Hook{}} = Webhooks.update_hook(hook, %{"code" => "alert()"})
  end

  test "delete_hook/1 deletes the hook" do
    hook = insert(:hook)
    assert {:ok, %Hook{}} = Webhooks.delete_hook(hook)
    assert {:error, :not_found} = Webhooks.get_hook(hook.id)
  end
end
