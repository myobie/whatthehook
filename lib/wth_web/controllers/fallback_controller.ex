defmodule WTHWeb.FallbackController do
  @moduledoc false
  use WTHWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(WTHWeb.ChangesetView, "error.json", changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> render(WTHWeb.ErrorView, "404.json", %{})
  end
end
