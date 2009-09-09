ActionController::Routing::Routes.draw do |map|

  map.connect '', :controller => 'login', :action => 'login'

  map.connect '/signup', :controller => 'login', :action => 'signup'
  map.connect '/screenshots', :controller => 'login', :action => 'screenshots'
  map.connect '/policy', :controller => 'login', :action => 'policy'
  map.connect '/terms', :controller => 'login', :action => 'terms'
  map.connect '/about', :controller => 'login', :action => 'about'
  
  map.home '/forums/index', :controller => 'forums', :action => 'index'

  map.resources(:resources, :collection => { 
                  :attributes => :get, 
                  :auto_complete_for_resource_parent => :get },
                :member => { :show_password => :get })

  map.resources :resource_types, :collection => { :attribute => :get }
  map.resources :organizational_units

  map.resources(:task_filters, 
                :member => { :select => :any },
                :collection => { 
                  :reset => :any, :search => :any, 
                  :update_current_filter => :any, 
                  :set_single_task_filter => :any })

  map.resources :forums do |forum|
    forum.resources :topics, :name_prefix => nil do |topic|
      topic.resources :posts, :name_prefix => nil
      topic.resource :topic_monitorship, :controller => :monitorships, :name_prefix => nil
    end
    forum.resource :monitorship, :controller => :monitorships, :name_prefix => nil
  end

  map.resources :posts, :name_prefix => 'all_', :collection => { :search => :get }
  map.resources :todos, :member => { :toggle_done => :post }
  map.resources :work_logs
  map.resources :tags

  map.resources(:work, :collection => { 
                  :start => :any,
                  :stop => :any,
                  :cancel => :any,
                  :pause => :any
                })

  %w(user forum).each do |attr|
    map.resources :posts, :name_prefix => "#{attr}_", :path_prefix => "/#{attr.pluralize}/:#{attr}_id"
  end

  map.formatted_monitored_posts 'users/:user_id/monitored.:format', :controller => 'posts', :action => 'monitored'
  map.monitored_posts           'users/:user_id/monitored', :controller => 'posts', :action => 'monitored'

  map.resources :properties

  map.connect ':controller/service.wsdl', :action => 'wsdl'

  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'


end
