Clockingit::Application.routes.draw do |map|
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get :short
  #       post :toggle
  #     end
  #
  #     collection do
  #       get :sold
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get :recent, :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
  
  root :to => 'login#login'

  match '/signup' => 'login#signup'
  match '/screenshots' => 'login#screenshots'
  match '/policy' => 'login#policy'
  match '/terms' => 'login#terms'
  match '/about' => 'login#about'

  map.home '/forums/index', :controller => 'forums', :action => 'index'
  
  map.resources(:resources, :collection => {
                  :attributes => :get,
                  :auto_complete_for_resource_parent => :get },
                :member => { :show_password => :get })

  map.resources :resource_types, :collection => { :attribute => :get }
  map.resources :organizational_units
  map.resources :pages, :collection => { :target_list => :any }

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
  map.resources(:tags, :collection=>{:auto_complete_for_tags=>:get})

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

  resources :properties
  resources :scm_projects
  resources :triggers
    
  map.connect 'api/scm/:provider/:secret_key', :controller => :scm_changesets, :action=> :create
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'


end
