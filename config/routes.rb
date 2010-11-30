Jobsworth::Application.routes.draw do
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
    match :select, :on => :member
    collection do
      get :recent
      get :reset
      get :search
      get :update_current_filter
      get :set_single_task_filter
    end
  end

  match '/forums/index' => 'forums#index', :as => :home
  resources :forums do
    resources :posts
  end
  scope "/forums/:forum_id" do
    resources :topics
    resource :monitorship, :controller => :monitorships, :only => [:create, :destroy]
  end
  scope "/forums/:forum_id/topics/:topic_id" do
    resources :posts
    resource :topic_monitorship, :controller => :monitorships, :only => [:create, :destroy]
  end

  resources :posts, :as => 'all_posts' do
  	collection do
  	 get :search
	  end
	end
  resources :todos do
	match :toggle_done, :on => :member
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

	match 'users/:user_id/monitored.:format' => 'posts#monitored', :as => :formatted_monitored_posts
  match 'users/:user_id/monitored' => 'posts#monitored', :as => :monitored_posts

  resources :properties
  resources :scm_projects
  resources :triggers
    
  match 'api/scm/:provider/:secret_key' => 'scm_changesets#create'
  match ':controller/service.wsdl', :action => 'wsdl'

  match ":controller(/:action(/:id(.:format)))"

end
