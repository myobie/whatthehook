defmodule Whathook.Web.PageController do
  use Whathook.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
