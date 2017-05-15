defmodule Whathook.Web.FallbackController do
  @moduledoc false
  use Whathook.Web, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(Whathook.Web.ChangesetView, "error.json", changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> render(Whathook.Web.ErrorView, "404.json", %{})
  end
end
