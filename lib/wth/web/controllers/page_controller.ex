defmodule WTH.Web.PageController do
  use WTH.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
