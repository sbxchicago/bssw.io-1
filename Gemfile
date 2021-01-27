# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.7.2'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.0'
# Use sqlite3 as the database for Active Record
gem 'mysql2'
gem 'sqlite3'

# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails' # , '6.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'execjs'

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', github: 'rails/jbuilder', branch: 'master'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Search Engine
gem 'sunspot_rails'
gem 'sunspot_solr'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'listen', '~> 3.0.5'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem 'bootstrap-sass'
gem 'factory_bot_rails'
gem 'faker'
gem 'github_api'
gem 'nikkou'
gem 'nokogiri'
gem 'rails-controller-testing'
gem 'redcarpet'
gem 'rspec'
gem 'rspec-rails'
gem 'simplecov'

group :development do
  gem 'capistrano', '~> 3.7'
  gem 'capistrano-rails', '~> 1.2'
end

gem 'capistrano-bundler'
gem 'capistrano-rvm'

gem 'acts-as-taggable-on', '~> 4.0'
gem 'chronic'
gem 'friendly_id', '5.3.0'

# gem 'progress_bar'
# gem 'sunspot_rails'
# gem 'sunspot_solr'

gem 'headhunter'
gem 'pry'
gem 'ransack'

gem 'truncate_html'

gem 'mail_form'
gem 'simple_form'

gem 'capybara'
gem 'capybara-email'

gem 'lightbox-bootstrap-rails'
gem 'will_paginate'

gem 'exception_handler'
gem 'exception_notification'

gem 'cloudinary'

gem 'attempt'

# gem 'rubycritic' #, '3.0.0'
# gem 'parser', '2.5.0.0'
# gem 'rubocop'
# gem 'reek'
# gem 'brakeman'

gem 'metric_fu'
gem 'reek'
gem 'rubocop'
gem 'rubocop-rails'
gem 'rubocop-rspec'
gem 'rubycritic'

gem 'ffi' # , '1.10.0'

gem 'recaptcha'

gem 'octokit'

gem 'awesome_print'

# gem 'rack-mini-profiler'
gem 'stemmify'

gem 'lemmatizer'

gem 'geocoder'
# gem 'cachethod'

gem 'mechanize'
gem 'rubyzip'

gem 'scout_apm'

gem 'activerecord-import'
gem 'store_method', github: 'fomichov/store_method'
# gem 'delayed_job_active_record'
# gem 'whenever'

gem 'sucker_punch'
