Jobsworth::Application.routes.draw do

  resources :snippets do
    get :reorder
  end

  resources :service_level_agreements, :only => [:create, :destroy, :update]

  resources :services, :except => [:show] do
    collection do
      get 'auto_complete_for_service_name'
    end
  end

  devise_for :users,
             :path_prefix => "auth",
             :controllers => { :sessions  => "auth/sessions",
                                :passwords => "auth/passwords" }

  resources :users, :except => [:show] do
    collection do
      get :auto_complete_for_user_name
    end
    member do
      match :access, :via => [:get, :put]
      get :emails
      get :projects
      get :tasks
      get :filters
      match :workplan, :via => [:get, :put]
      get :update_seen_news
    end
  end

  get 'activities/index', as: 'activities'
  root :to => 'activities#index'

  get '/unified_search' => "customers#search"
  resources :customers do
    collection do
      get :auto_complete_for_customer_name
    end
  end

  resources :news_items,  :except => [:show]
  resources :projects do
    collection do
      get :add_default_user
      get :list_completed
    end

    member do
      get :ajax_remove_permission
      get :ajax_add_permission
      post :complete
      post :revert
    end
  end

  # task routes
  get 'tasks/:id' => "tasks#edit", :constraints => {:id => /\d+/}
  get "tasks/view/:id" => "tasks#edit", :as => :task_view
  get "tasks/nextTasks/:count" => "tasks#nextTasks", :defaults => { :count => 5 }
  resources :tasks, :except => [:show] do
    collection do
      get   :auto_complete_for_dependency_targets
      get   :get_default_watchers_for_customer
      get   :get_default_watchers_for_project
      get   :get_default_watchers
      post  :change_task_weight
      get   :get_customer
      get   :billable
      get   :planning
    end
    member do
      post :set_group
      get :score
      get :clone
    end
  end

  resources :email_addresses, :except => [:show] do
    member do
      put :default
    end
  end

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
    member do
      get :toggle_status
      get :select
    end
    collection do
      get :search
      get :update_current_filter
      get :set_single_task_filter
    end
  end

  resources :todos do
    post :toggle_done, :on => :member
  end

  resources :work_logs do
    post :update_work_log, :on => :member
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
      get :refresh
    end
  end

  resources :properties do
    collection do
      get :remove_property_value_dialog
      post :remove_property_value
    end
  end

  resources :scm_projects
  resources :triggers

  post 'api/scm/:provider/:secret_key' => 'scm_changesets#create'

  resources :projects, :customers, :property_values do
    resources :score_rules
  end

  resources :milestones do
    resources :score_rules

    collection do
      get :get_milestones
    end

    member do
      post :revert
      post :complete
    end
  end

  resources :task_templates

  resources :companies do
    resources :score_rules
    collection do
      get :score_rules
      get :custom_scripts
      get :properties
    end
    member do
      get  :show_logo
    end
  end

  resources :emails, only: [:create]

  get 'timeline/list' => 'timeline#index'
  get 'tasks/list' => 'tasks#index'

  get 'feeds/rss/:id', :to => 'feeds#rss'
  get 'feeds/ical/:id', :to => 'feeds#ical'

  resources :admin_stats, :only => [:index]

  resources :billing, :only => [:index] do
    collection do
      get :get_csv
    end
  end

  resources :scm_changesets, :only => [:create] do
    collection do
      get :list
    end
  end

  resources :widgets, :except => [:index, :new] do
    collection do
      get :add
      get :toggle_display
      post :save_order
    end
  end

  get 'wiki(/:id)', :to => 'wiki#show'
  resources :wiki, :except => [:index, :new, :show] do
    member do
      get :versions
      get :cancel
      get :cancel_create
    end
  end

  resources :project_files, :only => [:show] do
    collection do
      get     :thumbnail
      delete  :destroy_file
    end
  end

  resources :custom_attribute, :only => [:index, :edit, :update] do
    collection do

    end
  end

  match ':controller/redirect_from_last' => :redirect_from_last, :via => [:get]

end
