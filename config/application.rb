# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Bss
  # application config file
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.generators do |g|
      g.fixture_replacement :factory_bot
    end
    require "#{Rails.root}/app/middleware/queryrescue.rb"

    config.middleware.insert 0, RefuseInvalidRequest
    config.middleware.insert 0, Rack::UTF8Sanitizer
  end
end
