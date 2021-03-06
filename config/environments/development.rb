Versioneye::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true
  config.action_controller.perform_caching = false
  config.cache_store = :dalli_store, ["#{Settings.instance.memcache_addr}:#{Settings.instance.memcache_port}"],{
    :username => Settings.instance.memcache_username, :password => Settings.instance.memcache_password,
    :namespace => 'veye', :expires_in => 1.day, :compress => true }

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local = false

  config.serve_static_files = true
  config.action_dispatch.x_sendfile_header = nil

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Compress JavaScripts and CSS
  config.assets.compress = false
  config.assets.css_compressor = :sass
  config.assets.js_compressor = :uglifier
  config.assets.debug = true
  config.assets.compile = true
  config.assets.digest = true
  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w( api_application.css *.js *.scss )

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = false

  # See everything in the log (default is :info)
  config.log_level = :debug
  config.logger = Logger.new("#{Rails.root}/log/#{Rails.env}_api.log", 10, 10.megabytes)

  config.i18n.fallbacks = true

  config.active_support.deprecation = :notify

  config.action_mailer.delivery_method = :test
  EmailSettingService.update_action_mailer_from_db
  Settings.instance.smtp_sender_email = EmailSettingService.email_setting.sender_email
  Settings.instance.smtp_sender_name  = EmailSettingService.email_setting.sender_name
  config.action_mailer.perform_deliveries    = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.raise_delivery_errors = true

  routes.default_url_options = { host: Settings.instance.server_host, port: Settings.instance.server_port }

  Octokit.configure do |c|
    c.api_endpoint = Settings.instance.github_api_url
    c.web_endpoint = Settings.instance.github_base_url
  end

end
