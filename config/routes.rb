Jobsworth::Application.routes.draw do
  devise_for :users, :controllers => {:sessions => "auth/sessions", :passwords => "auth/passwords"}

  # See how all your routes lay out with "rake routes"

  root :to => 'activities#list'
  post "project_files/upload" => "project_files#upload"
  get "projects/new" => "projects#new"
  get "project_files/list" => "project_files#list"
  post "tasks/change_task_weight" => "tasks#change_task_weight"
  get "tasks/nextTasks/:count" => "tasks#nextTasks", :defaults => { :count => 5 }

  resources :admin do
    collection do
      get :stats
      get :news
      get :logos
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

  match "tasks/view/:id" => "tasks#edit", :as => :task_view

  match ":controller(/:action(/:id(.:format)))"

end
#== Route Map
# Generated on 07 May 2011 21:58
#
#                            new_user_session GET    /users/sign_in(.:format)                               {:action=>"new", :controller=>"auth/sessions"}
#                                user_session POST   /users/sign_in(.:format)                               {:action=>"create", :controller=>"auth/sessions"}
#                        destroy_user_session GET    /users/sign_out(.:format)                              {:action=>"destroy", :controller=>"auth/sessions"}
#                               user_password POST   /users/password(.:format)                              {:action=>"create", :controller=>"auth/passwords"}
#                           new_user_password GET    /users/password/new(.:format)                          {:action=>"new", :controller=>"auth/passwords"}
#                          edit_user_password GET    /users/password/edit(.:format)                         {:action=>"edit", :controller=>"auth/passwords"}
#                                             PUT    /users/password(.:format)                              {:action=>"update", :controller=>"auth/passwords"}
#                           user_registration POST   /users(.:format)                                       {:action=>"create", :controller=>"devise/registrations"}
#                       new_user_registration GET    /users/sign_up(.:format)                               {:action=>"new", :controller=>"devise/registrations"}
#                      edit_user_registration GET    /users/edit(.:format)                                  {:action=>"edit", :controller=>"devise/registrations"}
#                                             PUT    /users(.:format)                                       {:action=>"update", :controller=>"devise/registrations"}
#                                             DELETE /users(.:format)                                       {:action=>"destroy", :controller=>"devise/registrations"}
#                                        root        /(.:format)                                            {:controller=>"activities", :action=>"list"}
#                        project_files_upload POST   /project_files/upload(.:format)                        {:controller=>"project_files", :action=>"upload"}
#                                projects_new GET    /projects/new(.:format)                                {:controller=>"projects", :action=>"new"}
#                          project_files_list GET    /project_files/list(.:format)                          {:controller=>"project_files", :action=>"list"}
#                    tasks_change_task_weight POST   /tasks/change_task_weight(.:format)                    {:controller=>"tasks", :action=>"change_task_weight"}
#                                             GET    /tasks/nextTasks/:count(.:format)                      {:count=>5, :controller=>"tasks", :action=>"nextTasks"}
#                           stats_admin_index GET    /admin/stats(.:format)                                 {:action=>"stats", :controller=>"admin"}
#                            news_admin_index GET    /admin/news(.:format)                                  {:action=>"news", :controller=>"admin"}
#                           logos_admin_index GET    /admin/logos(.:format)                                 {:action=>"logos", :controller=>"admin"}
#                                 admin_index GET    /admin(.:format)                                       {:action=>"index", :controller=>"admin"}
#                                             POST   /admin(.:format)                                       {:action=>"create", :controller=>"admin"}
#                                   new_admin GET    /admin/new(.:format)                                   {:action=>"new", :controller=>"admin"}
#                                  edit_admin GET    /admin/:id/edit(.:format)                              {:action=>"edit", :controller=>"admin"}
#                                       admin GET    /admin/:id(.:format)                                   {:action=>"show", :controller=>"admin"}
#                                             PUT    /admin/:id(.:format)                                   {:action=>"update", :controller=>"admin"}
#                                             DELETE /admin/:id(.:format)                                   {:action=>"destroy", :controller=>"admin"}
#                        attributes_resources GET    /resources/attributes(.:format)                        {:action=>"attributes", :controller=>"resources"}
# auto_complete_for_resource_parent_resources GET    /resources/auto_complete_for_resource_parent(.:format) {:action=>"auto_complete_for_resource_parent", :controller=>"resources"}
#                      show_password_resource GET    /resources/:id/show_password(.:format)                 {:action=>"show_password", :controller=>"resources"}
#                                   resources GET    /resources(.:format)                                   {:action=>"index", :controller=>"resources"}
#                                             POST   /resources(.:format)                                   {:action=>"create", :controller=>"resources"}
#                                new_resource GET    /resources/new(.:format)                               {:action=>"new", :controller=>"resources"}
#                               edit_resource GET    /resources/:id/edit(.:format)                          {:action=>"edit", :controller=>"resources"}
#                                    resource GET    /resources/:id(.:format)                               {:action=>"show", :controller=>"resources"}
#                                             PUT    /resources/:id(.:format)                               {:action=>"update", :controller=>"resources"}
#                                             DELETE /resources/:id(.:format)                               {:action=>"destroy", :controller=>"resources"}
#                    attribute_resource_types GET    /resource_types/attribute(.:format)                    {:action=>"attribute", :controller=>"resource_types"}
#                              resource_types GET    /resource_types(.:format)                              {:action=>"index", :controller=>"resource_types"}
#                                             POST   /resource_types(.:format)                              {:action=>"create", :controller=>"resource_types"}
#                           new_resource_type GET    /resource_types/new(.:format)                          {:action=>"new", :controller=>"resource_types"}
#                          edit_resource_type GET    /resource_types/:id/edit(.:format)                     {:action=>"edit", :controller=>"resource_types"}
#                               resource_type GET    /resource_types/:id(.:format)                          {:action=>"show", :controller=>"resource_types"}
#                                             PUT    /resource_types/:id(.:format)                          {:action=>"update", :controller=>"resource_types"}
#                                             DELETE /resource_types/:id(.:format)                          {:action=>"destroy", :controller=>"resource_types"}
#                        organizational_units GET    /organizational_units(.:format)                        {:action=>"index", :controller=>"organizational_units"}
#                                             POST   /organizational_units(.:format)                        {:action=>"create", :controller=>"organizational_units"}
#                     new_organizational_unit GET    /organizational_units/new(.:format)                    {:action=>"new", :controller=>"organizational_units"}
#                    edit_organizational_unit GET    /organizational_units/:id/edit(.:format)               {:action=>"edit", :controller=>"organizational_units"}
#                         organizational_unit GET    /organizational_units/:id(.:format)                    {:action=>"show", :controller=>"organizational_units"}
#                                             PUT    /organizational_units/:id(.:format)                    {:action=>"update", :controller=>"organizational_units"}
#                                             DELETE /organizational_units/:id(.:format)                    {:action=>"destroy", :controller=>"organizational_units"}
#                           target_list_pages GET    /pages/target_list(.:format)                           {:action=>"target_list", :controller=>"pages"}
#                                       pages GET    /pages(.:format)                                       {:action=>"index", :controller=>"pages"}
#                                             POST   /pages(.:format)                                       {:action=>"create", :controller=>"pages"}
#                                    new_page GET    /pages/new(.:format)                                   {:action=>"new", :controller=>"pages"}
#                                   edit_page GET    /pages/:id/edit(.:format)                              {:action=>"edit", :controller=>"pages"}
#                                        page GET    /pages/:id(.:format)                                   {:action=>"show", :controller=>"pages"}
#                                             PUT    /pages/:id(.:format)                                   {:action=>"update", :controller=>"pages"}
#                                             DELETE /pages/:id(.:format)                                   {:action=>"destroy", :controller=>"pages"}
#                   toggle_status_task_filter GET    /task_filters/:id/toggle_status(.:format)              {:action=>"toggle_status", :controller=>"task_filters"}
#                          select_task_filter        /task_filters/:id/select(.:format)                     {:action=>"select", :controller=>"task_filters"}
#                         manage_task_filters GET    /task_filters/manage(.:format)                         {:action=>"manage", :controller=>"task_filters"}
#                         recent_task_filters GET    /task_filters/recent(.:format)                         {:action=>"recent", :controller=>"task_filters"}
#                          reset_task_filters GET    /task_filters/reset(.:format)                          {:action=>"reset", :controller=>"task_filters"}
#                         search_task_filters GET    /task_filters/search(.:format)                         {:action=>"search", :controller=>"task_filters"}
#          update_current_filter_task_filters GET    /task_filters/update_current_filter(.:format)          {:action=>"update_current_filter", :controller=>"task_filters"}
#         set_single_task_filter_task_filters GET    /task_filters/set_single_task_filter(.:format)         {:action=>"set_single_task_filter", :controller=>"task_filters"}
#                                task_filters GET    /task_filters(.:format)                                {:action=>"index", :controller=>"task_filters"}
#                                             POST   /task_filters(.:format)                                {:action=>"create", :controller=>"task_filters"}
#                             new_task_filter GET    /task_filters/new(.:format)                            {:action=>"new", :controller=>"task_filters"}
#                            edit_task_filter GET    /task_filters/:id/edit(.:format)                       {:action=>"edit", :controller=>"task_filters"}
#                                 task_filter GET    /task_filters/:id(.:format)                            {:action=>"show", :controller=>"task_filters"}
#                                             PUT    /task_filters/:id(.:format)                            {:action=>"update", :controller=>"task_filters"}
#                                             DELETE /task_filters/:id(.:format)                            {:action=>"destroy", :controller=>"task_filters"}
#                            toggle_done_todo        /todos/:id/toggle_done(.:format)                       {:action=>"toggle_done", :controller=>"todos"}
#                                       todos GET    /todos(.:format)                                       {:action=>"index", :controller=>"todos"}
#                                             POST   /todos(.:format)                                       {:action=>"create", :controller=>"todos"}
#                                    new_todo GET    /todos/new(.:format)                                   {:action=>"new", :controller=>"todos"}
#                                   edit_todo GET    /todos/:id/edit(.:format)                              {:action=>"edit", :controller=>"todos"}
#                                        todo GET    /todos/:id(.:format)                                   {:action=>"show", :controller=>"todos"}
#                                             PUT    /todos/:id(.:format)                                   {:action=>"update", :controller=>"todos"}
#                                             DELETE /todos/:id(.:format)                                   {:action=>"destroy", :controller=>"todos"}
#                    update_work_log_work_log        /work_logs/:id/update_work_log(.:format)               {:action=>"update_work_log", :controller=>"work_logs"}
#                                   work_logs GET    /work_logs(.:format)                                   {:action=>"index", :controller=>"work_logs"}
#                                             POST   /work_logs(.:format)                                   {:action=>"create", :controller=>"work_logs"}
#                                new_work_log GET    /work_logs/new(.:format)                               {:action=>"new", :controller=>"work_logs"}
#                               edit_work_log GET    /work_logs/:id/edit(.:format)                          {:action=>"edit", :controller=>"work_logs"}
#                                    work_log GET    /work_logs/:id(.:format)                               {:action=>"show", :controller=>"work_logs"}
#                                             PUT    /work_logs/:id(.:format)                               {:action=>"update", :controller=>"work_logs"}
#                                             DELETE /work_logs/:id(.:format)                               {:action=>"destroy", :controller=>"work_logs"}
#                 auto_complete_for_tags_tags GET    /tags/auto_complete_for_tags(.:format)                 {:action=>"auto_complete_for_tags", :controller=>"tags"}
#                                        tags GET    /tags(.:format)                                        {:action=>"index", :controller=>"tags"}
#                                             POST   /tags(.:format)                                        {:action=>"create", :controller=>"tags"}
#                                     new_tag GET    /tags/new(.:format)                                    {:action=>"new", :controller=>"tags"}
#                                    edit_tag GET    /tags/:id/edit(.:format)                               {:action=>"edit", :controller=>"tags"}
#                                         tag GET    /tags/:id(.:format)                                    {:action=>"show", :controller=>"tags"}
#                                             PUT    /tags/:id(.:format)                                    {:action=>"update", :controller=>"tags"}
#                                             DELETE /tags/:id(.:format)                                    {:action=>"destroy", :controller=>"tags"}
#                            start_work_index GET    /work/start(.:format)                                  {:action=>"start", :controller=>"work"}
#                             stop_work_index GET    /work/stop(.:format)                                   {:action=>"stop", :controller=>"work"}
#                           cancel_work_index GET    /work/cancel(.:format)                                 {:action=>"cancel", :controller=>"work"}
#                            pause_work_index GET    /work/pause(.:format)                                  {:action=>"pause", :controller=>"work"}
#                                  work_index GET    /work(.:format)                                        {:action=>"index", :controller=>"work"}
#                                             POST   /work(.:format)                                        {:action=>"create", :controller=>"work"}
#                                    new_work GET    /work/new(.:format)                                    {:action=>"new", :controller=>"work"}
#                                   edit_work GET    /work/:id/edit(.:format)                               {:action=>"edit", :controller=>"work"}
#                                        work GET    /work/:id(.:format)                                    {:action=>"show", :controller=>"work"}
#                                             PUT    /work/:id(.:format)                                    {:action=>"update", :controller=>"work"}
#                                             DELETE /work/:id(.:format)                                    {:action=>"destroy", :controller=>"work"}
#                                  properties GET    /properties(.:format)                                  {:action=>"index", :controller=>"properties"}
#                                             POST   /properties(.:format)                                  {:action=>"create", :controller=>"properties"}
#                                new_property GET    /properties/new(.:format)                              {:action=>"new", :controller=>"properties"}
#                               edit_property GET    /properties/:id/edit(.:format)                         {:action=>"edit", :controller=>"properties"}
#                                    property GET    /properties/:id(.:format)                              {:action=>"show", :controller=>"properties"}
#                                             PUT    /properties/:id(.:format)                              {:action=>"update", :controller=>"properties"}
#                                             DELETE /properties/:id(.:format)                              {:action=>"destroy", :controller=>"properties"}
#                                scm_projects GET    /scm_projects(.:format)                                {:action=>"index", :controller=>"scm_projects"}
#                                             POST   /scm_projects(.:format)                                {:action=>"create", :controller=>"scm_projects"}
#                             new_scm_project GET    /scm_projects/new(.:format)                            {:action=>"new", :controller=>"scm_projects"}
#                            edit_scm_project GET    /scm_projects/:id/edit(.:format)                       {:action=>"edit", :controller=>"scm_projects"}
#                                 scm_project GET    /scm_projects/:id(.:format)                            {:action=>"show", :controller=>"scm_projects"}
#                                             PUT    /scm_projects/:id(.:format)                            {:action=>"update", :controller=>"scm_projects"}
#                                             DELETE /scm_projects/:id(.:format)                            {:action=>"destroy", :controller=>"scm_projects"}
#                                    triggers GET    /triggers(.:format)                                    {:action=>"index", :controller=>"triggers"}
#                                             POST   /triggers(.:format)                                    {:action=>"create", :controller=>"triggers"}
#                                 new_trigger GET    /triggers/new(.:format)                                {:action=>"new", :controller=>"triggers"}
#                                edit_trigger GET    /triggers/:id/edit(.:format)                           {:action=>"edit", :controller=>"triggers"}
#                                     trigger GET    /triggers/:id(.:format)                                {:action=>"show", :controller=>"triggers"}
#                                             PUT    /triggers/:id(.:format)                                {:action=>"update", :controller=>"triggers"}
#                                             DELETE /triggers/:id(.:format)                                {:action=>"destroy", :controller=>"triggers"}
#                                                    /api/scm/:provider/:secret_key(.:format)               {:controller=>"scm_changesets", :action=>"create"}
#                                                    /:controller/service.wsdl(.:format)                    {:action=>"wsdl"}
#                                   task_view        /tasks/view/:id(.:format)                              {:controller=>"tasks", :action=>"edit"}
#                                                    /:controller(/:action(/:id(.:format)))                 
# Loaded suite /Users/ari/.rvm/gems/ruby-1.9.2-p0/bin/rake
# Started
# 
# 
# Finished in 0.000262 seconds.
# 
# 0 tests, 0 assertions, 0 failures, 0 errors, 0 pendings, 0 omissions, 0 notifications
# 0% passed
# 
# 0.00 tests/s, 0.00 assertions/s
