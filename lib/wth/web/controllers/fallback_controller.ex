defmodule WTH.Web.FallbackController do
  @moduledoc false
  use WTH.Web, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(WTH.Web.ChangesetView, "error.json", changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> render(WTH.Web.ErrorView, "404.json", %{})
  end
end
