Jobsworth::Application.routes.draw do

  resources :snippets

  resources :service_level_agreements, :only => [:create, :destroy, :update]

  resources :services, :except => [:show] do
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
  resources :projects do
    get 'list_completed', :on => :collection
    get 'ajax_add_permission', :on => :member
  end

  # task routes
  get 'tasks/:id' => "tasks#edit", :constraints => {:id => /\d+/}
  get "tasks/view/:id" => "tasks#edit", :as => :task_view
  get "tasks/nextTasks/:count" => "tasks#nextTasks", :defaults => { :count => 5 }
  resources :tasks, :except => [:show] do
    collection do
      post 'change_task_weight'
      get  'billable'
      get 'planning'
    end
    member do
      get 'score'
    end
  end

  resources :email_addresses, :only => [:index, :update, :edit]

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

  resources :task_templates

  resources :companies do
    resources :score_rules
    member do
      get  :show_logo
    end
  end

  match ':controller/list' => ':controller#index'

  match ":controller(/:action(/:id(.:format)))"
end
