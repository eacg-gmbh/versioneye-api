Versioneye::Application.routes.draw do

  mount VersionEye::API => '/api'

  root :to => "swaggers#index"

  get   '/api',                 :to => 'swaggers#index'
  get   '/swaggers',            :to => redirect('/api')
  get   '/apijson',             :to => redirect('/api')
  get   '/apijson_tools',       :to => redirect('/api')
  get   '/apijson_libs',        :to => redirect('/api')

end
