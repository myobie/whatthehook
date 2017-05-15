defmodule Whathook.Web.HookControllerTest do
  use Whathook.Web.ConnCase

  alias Whathook.Webhooks.Hook

  setup %{conn: conn} do
    conn = conn
           |> put_req_header("accept", "application/json")

    {:ok, conn: conn}
  end

  test "creates hook and renders hook when data is valid", %{conn: conn} do
    conn = post conn, hook_path(conn, :create), string_params_for(:hook)
    assert %{"id" => id} = json_response(conn, 201)

    conn = get conn, hook_path(conn, :show, id)
    assert json_response(conn, 200)
  end

  test "updates chosen hook and renders hook when data is valid", %{conn: conn} do
    %Hook{id: id} = hook = insert(:hook)

    conn = put conn, hook_path(conn, :update, hook), code: "alert()"
    assert %{"id" => ^id} = json_response(conn, 200)

    conn = get conn, hook_path(conn, :show, id)
    assert json_response(conn, 200)
  end

  test "deletes chosen hook", %{conn: conn} do
    hook = insert(:hook)

    conn = delete conn, hook_path(conn, :delete, hook)
    assert response(conn, 204)

    conn = get conn, hook_path(conn, :show, hook)
    assert json_response(conn, 404)
  end
end
