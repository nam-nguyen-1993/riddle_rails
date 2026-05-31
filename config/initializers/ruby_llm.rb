RubyLLM.configure do |config|
  config.openai_api_base = "https://prepend.me/api.openai.com/v1"
  config.openai_api_key = ENV["PREPEND_TOKEN_OPENAI"]
end
