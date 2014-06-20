source 'http://rubygems.org'
ruby "2.1.1"

gem 'rails'              , '~> 3.2.17'
gem 'unicorn'            , '~> 4.8.2'
gem 'grape'              , '~> 0.7.0'
gem 'grape-entity'       , '~> 0.3.0'
gem 'grape-swagger'      , :path => "vendor/gems" # , :github => "timgluz/grape-swagger", :branch => "master"
gem 'ruby_regex'         , '~> 0.1.0'
gem 'will_paginate_mongoid', '2.0.1'
gem 'htmlentities'       , '~> 4.3.1'

gem 'versioneye-core'    , :git => 'git@github.com:versioneye/versioneye-core.git', :tag => 'v2.0.0'
# gem 'versioneye-core'    , :path => "~/workspace/versioneye/versioneye-core"

group :assets do
  gem 'therubyracer'          , '~> 0.12.0'
  gem 'sass'                  , :require => 'sass'
  gem 'sass-rails'            , '~> 3.2.6'
  gem 'coffee-rails'          , '~> 3.2.0'
  gem 'uglifier'              , '~> 2.5.0'
  gem 'yui-compressor'        , '~> 0.12.0'
  gem 'turbo-sprockets-rails3', '~> 0.3.0'
end

group :development do
  gem 'capistrano'        , '3.2.1'
  gem 'capistrano-rails'  , '1.1.1'
  gem 'capistrano-bundler', '1.1.2'
  gem 'psych'             , '~> 2.0.5'
  gem 'irbtools'          , '1.6.1'
  gem 'terminal-notifier' , '~> 1.6.0'
  gem 'fakes3'            , '0.1.5.2'
  gem 'debugger'          , '~> 1.6.0'
end

group :test do
  gem 'simplecov'         , '~> 0.8.0'
  gem 'turn'              , :require => false
  gem 'rspec'             , '~> 2.14.0'
  gem 'rspec-rails'       , '~> 2.14.0'
  gem 'rspec-mocks'       , '~> 2.14.0'
  gem 'capybara'          , '~> 2.2.0'
  gem 'capybara-firebug'  , '~> 2.0.0'
  gem 'fakeweb'           , '~> 1.3.0'
  gem 'vcr'               , '~> 2.9.0',  :require => false
  gem 'webmock'           , '~> 1.18.0', :require => false
  gem 'database_cleaner'  , '~> 1.2.0'
  gem 'factory_girl'      , '~> 4.4.0'
  gem 'factory_girl_rails', '~> 4.4.0'
end
