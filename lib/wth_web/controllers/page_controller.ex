defmodule WTHWeb.PageController do
  use WTHWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
