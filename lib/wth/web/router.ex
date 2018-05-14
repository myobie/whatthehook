defmodule WTH.Web.Router do
  use WTH.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WTH.Web do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/api", WTH.Web do
    pipe_through :api

    resources "/hooks", HookController, except: [:index, :new, :edit]
  end
end
