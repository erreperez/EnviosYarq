require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Enviosyarq
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
    # config.web_console.whiny_requests = false
    # config.web_console.whitelisted_ips = '10.240.1.19'
    # config.web_console.whitelisted_ips = '10.240.0.91'
    # config.web_console.whitelisted_ips = '10.240.0.229'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
