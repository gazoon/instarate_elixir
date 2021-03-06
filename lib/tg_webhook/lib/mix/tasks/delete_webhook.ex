defmodule Mix.Tasks.SetWebhook do
  use Mix.Task
  require Logger

  def run(_args) do
    Application.ensure_all_started(:httpoison)
    bot_tokens= for {token,_} <- Application.get_env(:tg_webhook,:known_bots), do: token
    Enum.each(bot_tokens, &set_webhook/1)
  end

  def set_webhook(token) do

    Logger.info("Set webhook for #{token}")
    resp=HTTPoison.post!("https://api.telegram.org/bot#{token}/setWebhook",
      {:form, [
        {"url", Application.get_env(:tg_webhook, :public_url) <> "/update/" <> token},
        {"max_connections", 100}
      ]}
    )
    Logger.info("API response code=#{resp.status_code} body=#{resp.body}")
  end

end
