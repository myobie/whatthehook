defmodule Whathook.Factory do
  use ExMachina.Ecto, repo: Whathook.Repo

  def hook_factory do
    %Whathook.Webhooks.Hook{
      code: "export default () => {}",
      endpoint: "http://example.com/callback"
    }
  end
end
