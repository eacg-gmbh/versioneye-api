source 'http://rubygems.org'

gem 'tzinfo-data'
gem 'bundler'            , '~> 1.12.0'
gem 'rails'              , '4.2.6'
gem 'execjs'             , '~> 2.7.0'
gem 'therubyracer'       , '~> 0.12.0'
gem 'puma'               , '~> 3.4.0'
gem 'grape'              , '~> 0.7.0'
gem 'grape-entity'       , '0.3.0'
gem 'grape-swagger'      , :path => "vendor/gems" # , :github => "timgluz/grape-swagger", :branch => "master"
# gem 'grape-swagger'      , '0.10.1'
gem 'ruby_regex'         , '~> 0.1.0'
gem 'will_paginate_mongoid', '2.0.1'
gem 'htmlentities'       , '~> 4.3.2'

gem 'versioneye-core'    , :git => 'https://github.com/versioneye/versioneye-core.git', :tag => 'v9.3.1'
# gem 'versioneye-core'    , :path => "~/workspace/versioneye/versioneye-core"

gem 'font-awesome-sass', '~> 4.6.2'

group :assets do
  gem 'sass'                  , :require => 'sass'
  gem 'sass-rails'            , '~> 5.0.3'
  gem 'coffee-rails'          , '~> 4.1.0'
  gem 'uglifier'              , '~> 3.0.0'
end

group :development do
  gem 'psych'             , '~> 2.1.0'
  gem 'terminal-notifier' , '~> 1.6.0'
  gem 'fakes3'            , '~> 0.2.0'
end

group :test do
  gem 'simplecov'         , '~> 0.12.0'
  gem 'turn'              , :require => false
  gem 'rspec'             , '~> 3.2'
  gem 'rspec-rails'       , '~> 3.2'
  gem 'rspec_junit_formatter', '0.2.3'
  gem 'rspec-mocks'       , '~> 3.2'
  gem 'capybara'          , '~> 2.7.0'
  gem 'capybara-firebug'  , '~> 2.1.0'
  gem 'vcr'               , '~> 3.0.1',  :require => false
  gem 'webmock'           , '~> 2.1.0', :require => false
  gem 'database_cleaner'  , '~> 1.5.1'
  gem 'factory_girl'      , '~> 4.7.0'
  gem 'factory_girl_rails', '~> 4.7.0'
end

source 'https://rails-assets.org' do
  gem 'rails-assets-bootstrap'      , '3.3.6'
end
