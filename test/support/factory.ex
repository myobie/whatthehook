defmodule WTH.Factory do
  use ExMachina.Ecto, repo: WTH.Repo

  def hook_factory do
    %WTH.Webhooks.Hook{
      code: "export default () => {}",
      endpoint: "http://example.com/callback"
    }
  end
end
