defmodule WTH.Web.HookView do
  use WTH.Web, :view
  alias WTH.Web.HookView

  def render("index.json", %{hooks: hooks}) do
    render_many(hooks, HookView, "hook.json")
  end

  def render("show.json", %{hook: hook}) do
    render_one(hook, HookView, "hook.json")
  end

  def render("hook.json", %{hook: hook}) do
    %{id: hook.id,
      endpoint: hook.endpoint,
      code: hook.code}
  end
end
