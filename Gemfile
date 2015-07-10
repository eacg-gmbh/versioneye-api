source 'http://rubygems.org'

gem 'bundler'            , '~> 1.10.5'
gem 'rails'              , '~> 4.2.1'
gem 'puma'               , '~> 2.11.3'
gem 'grape'              , '~> 0.7.0'
gem 'grape-entity'       , '0.3.0'
gem 'grape-swagger'      , :path => "vendor/gems" # , :github => "timgluz/grape-swagger", :branch => "master"
# gem 'grape-swagger'      , '0.10.1'
gem 'ruby_regex'         , '~> 0.1.0'
gem 'will_paginate_mongoid', '2.0.1'
gem 'htmlentities'       , '~> 4.3.2'

gem 'versioneye-core'    , :git => 'git@github.com:versioneye/versioneye-core.git', :tag => 'v7.19.4'
# gem 'versioneye-core'    , :path => "~/workspace/versioneye/versioneye-core"

group :assets do
  gem 'therubyracer'          , '~> 0.12.0'
  gem 'sass'                  , :require => 'sass'
  gem 'sass-rails'            , '~> 5.0.3'
  gem 'coffee-rails'          , '~> 4.1.0'
  gem 'uglifier'              , '~> 2.7.0'
  gem 'yui-compressor'        , '~> 0.12.0'
end

group :development do
  gem 'psych'             , '~> 2.0.5'
  gem 'terminal-notifier' , '~> 1.6.0'
  gem 'fakes3'            , '~> 0.2.0'
end

group :test do
  gem 'simplecov'         , '~> 0.10.0'
  gem 'turn'              , :require => false
  gem 'rspec'             , '~> 3.2'
  gem 'rspec-rails'       , '~> 3.2'
  gem 'rspec-mocks'       , '~> 3.2'
  gem 'capybara'          , '~> 2.4.4'
  gem 'capybara-firebug'  , '~> 2.1.0'
  gem 'vcr'               , '~> 2.9.2',  :require => false
  gem 'webmock'           , '~> 1.21.0', :require => false
  gem 'database_cleaner'  , '~> 1.4.1'
  gem 'factory_girl'      , '~> 4.5.0'
  gem 'factory_girl_rails', '~> 4.5.0'
end
