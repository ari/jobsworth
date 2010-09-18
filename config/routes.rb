Clockingit::Application.routes.draw do |map|
  # See how all your routes lay out with "rake routes"

  root :to => 'login#login'

  match '/signup' => 'login#signup'
  match '/screenshots' => 'login#screenshots'
  match '/policy' => 'login#policy'
  match '/terms' => 'login#terms'
  match '/about' => 'login#about'

  resources :resources do
  	collection do
  		get :attributes
  		get :auto_complete_for_resource_parent
  	end
  	get :show_password, :on => :member
  end
  
  resources :resource_types do 
  	collection do
  		get :attribute
  	end
  end
  
  resources :organizational_units
  
  resources :pages do
  	collection do
  		get :target_list
  	end
	end

  resources :task_filters do
	  get :select, :on => :member
  	collection do
      get :reset
      get :search
      get :update_current_filter
      get :set_single_task_filter
	  end
  end

  match '/forums/index' => 'forums#index'
  resources :forums do
    resources :topics, :name_prefix => nil do
      resources :posts, :name_prefix => nil
      resource :topic_monitorship, :controller => :monitorships, :name_prefix => nil
    end
    resource :monitorship, :controller => :monitorships, :name_prefix => nil
  end

  resources :posts, :name_prefix => 'all_' do
  	collection do
  	 get :search
	  end
	end
  resources :todos do
  	post :toggle_done, :on => :member
  end
  
  resources :work_logs
  
  resources :tags do
  	collection do
	  	get :auto_complete_for_tags
		end
	end
	
  resources :work do
  	collection do
	    get :start
	    get :stop
	    get :cancel
	    get :pause
    end
  end

# The following is commented since I don't know what it does
#  %w(user forum).each do |attr|
#    map.resources :posts, :name_prefix => "#{attr}_", :path_prefix => "/#{attr.pluralize}/:#{attr}_id"
#  end

	match 'users/:user_id/monitored.:format' => 'posts#monitored', :as => :formatted_monitored_posts
  match 'users/:user_id/monitored' => 'posts#monitored', :as => :monitored_posts

  resources :properties
  resources :scm_projects
  resources :triggers
    
  match 'api/scm/:provider/:secret_key' => 'scm_changesets#create'
  match ':controller/service.wsdl', :action => 'wsdl'

  match ':controller(/:action(/:id(.:format)))'

end