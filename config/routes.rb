Jobsworth::Application.routes.draw do

  resources :service_level_agreements, :only => [:create, :destroy, :update]

  resources :services do
    collection do
      get 'auto_complete_for_service_name'
    end
  end

  devise_for  :users, 
              :controllers => { :sessions  => "auth/sessions", 
                                :passwords => "auth/passwords" }

  get 'activities/index', as: 'activities'
  root :to => 'activities#index'

  get '/unified_search' => "customers#search"
  resources :customers do
    collection do
      get 'auto_complete_for_customer_name'
    end
  end

  resources :news_items,  :except => [:show]
  resources :projects,    :except => [:show] do
    get 'list_completed', :on => :collection
  end

  # task routes
  get 'tasks/score/:task_num' => 'tasks#score'
  get 'tasks/:id' => "tasks#edit", :constraints => {:id => /\d+/}
  get "tasks/view/:id" => "tasks#edit", :as => :task_view
  get "tasks/nextTasks/:count" => "tasks#nextTasks", :defaults => { :count => 5 }
  resources :tasks, :except => [:show] do
    collection do
      post 'change_task_weight'
      get  'billable'
    end
  end

  resources :email_addresses, :only => [:update, :edit]

  post "project_files/upload" => "project_files#upload"
  get "project_files/list" => "project_files#list"

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
    get :toggle_status, :on => :member
    match :select, :on => :member
    collection do
      get :manage
      get :recent
      get :reset
      get :search
      get :update_current_filter
      get :set_single_task_filter
    end
  end

  resources :todos do
    match :toggle_done, :on => :member
  end

  resources :work_logs do 
    match :update_work_log, :on=> :member
  end

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

  resources :properties
  resources :scm_projects
  resources :triggers

  match 'api/scm/:provider/:secret_key' => 'scm_changesets#create'
  match ':controller/service.wsdl', :action => 'wsdl'


  get 'projects/:id/ajax_add_permission'      => 'projects#ajax_add_permission'

  resources :projects, :customers, :property_values do
    resources :score_rules
  end

  resources :milestones do
    resources :score_rules

    collection do
      get :get_milestones
      get :list_completed
    end

    member do
      get :revert
      get :complete
    end
  end

  resources :companies do
    resources :score_rules
    member do
      get  :show_logo
      post :delete_logo
    end
    collection do
      post :upload_logo
    end
  end

  match ':controller/list' => ':controller#index'

  match ":controller(/:action(/:id(.:format)))"
end
