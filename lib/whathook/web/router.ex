defmodule Whathook.Web.Router do
  use Whathook.Web, :router

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

  scope "/", Whathook.Web do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/api", Whathook.Web do
    pipe_through :api

    resources "/hooks", HookController, except: [:index, :new, :edit]
  end
end
