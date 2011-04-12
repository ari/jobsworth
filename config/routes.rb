Jobsworth::Application.routes.draw do
  devise_for :users, :controllers => {:sessions => "sessions", :passwords => "passwords"}

  # See how all your routes lay out with "rake routes"

  root :to => 'activities#list'

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

  match 'users/:user_id/monitored.:format' => 'posts#monitored', :as => :formatted_monitored_posts
  match 'users/:user_id/monitored' => 'posts#monitored', :as => :monitored_posts

  resources :properties
  resources :scm_projects
  resources :triggers

  match 'api/scm/:provider/:secret_key' => 'scm_changesets#create'
  match ':controller/service.wsdl', :action => 'wsdl'

  match "tasks/view/:id" => "tasks#edit"

  match ":controller(/:action(/:id(.:format)))"

end
#== Route Map
# Generated on 24 Dec 2010 14:27
#
#                                        root        /(.:format)                                                    {:controller=>"login", :action=>"login"}
#                                      signup        /signup(.:format)                                              {:controller=>"login", :action=>"signup"}
#                                 screenshots        /screenshots(.:format)                                         {:controller=>"login", :action=>"screenshots"}
#                                      policy        /policy(.:format)                                              {:controller=>"login", :action=>"policy"}
#                                       terms        /terms(.:format)                                               {:controller=>"login", :action=>"terms"}
#                                       about        /about(.:format)                                               {:controller=>"login", :action=>"about"}
#                        attributes_resources GET    /resources/attributes(.:format)                                {:action=>"attributes", :controller=>"resources"}
# auto_complete_for_resource_parent_resources GET    /resources/auto_complete_for_resource_parent(.:format)         {:action=>"auto_complete_for_resource_parent", :controller=>"resources"}
#                      show_password_resource GET    /resources/:id/show_password(.:format)                         {:action=>"show_password", :controller=>"resources"}
#                                   resources GET    /resources(.:format)                                           {:action=>"index", :controller=>"resources"}
#                                             POST   /resources(.:format)                                           {:action=>"create", :controller=>"resources"}
#                                new_resource GET    /resources/new(.:format)                                       {:action=>"new", :controller=>"resources"}
#                               edit_resource GET    /resources/:id/edit(.:format)                                  {:action=>"edit", :controller=>"resources"}
#                                    resource GET    /resources/:id(.:format)                                       {:action=>"show", :controller=>"resources"}
#                                             PUT    /resources/:id(.:format)                                       {:action=>"update", :controller=>"resources"}
#                                             DELETE /resources/:id(.:format)                                       {:action=>"destroy", :controller=>"resources"}
#                    attribute_resource_types GET    /resource_types/attribute(.:format)                            {:action=>"attribute", :controller=>"resource_types"}
#                              resource_types GET    /resource_types(.:format)                                      {:action=>"index", :controller=>"resource_types"}
#                                             POST   /resource_types(.:format)                                      {:action=>"create", :controller=>"resource_types"}
#                           new_resource_type GET    /resource_types/new(.:format)                                  {:action=>"new", :controller=>"resource_types"}
#                          edit_resource_type GET    /resource_types/:id/edit(.:format)                             {:action=>"edit", :controller=>"resource_types"}
#                               resource_type GET    /resource_types/:id(.:format)                                  {:action=>"show", :controller=>"resource_types"}
#                                             PUT    /resource_types/:id(.:format)                                  {:action=>"update", :controller=>"resource_types"}
#                                             DELETE /resource_types/:id(.:format)                                  {:action=>"destroy", :controller=>"resource_types"}
#                        organizational_units GET    /organizational_units(.:format)                                {:action=>"index", :controller=>"organizational_units"}
#                                             POST   /organizational_units(.:format)                                {:action=>"create", :controller=>"organizational_units"}
#                     new_organizational_unit GET    /organizational_units/new(.:format)                            {:action=>"new", :controller=>"organizational_units"}
#                    edit_organizational_unit GET    /organizational_units/:id/edit(.:format)                       {:action=>"edit", :controller=>"organizational_units"}
#                         organizational_unit GET    /organizational_units/:id(.:format)                            {:action=>"show", :controller=>"organizational_units"}
#                                             PUT    /organizational_units/:id(.:format)                            {:action=>"update", :controller=>"organizational_units"}
#                                             DELETE /organizational_units/:id(.:format)                            {:action=>"destroy", :controller=>"organizational_units"}
#                           target_list_pages GET    /pages/target_list(.:format)                                   {:action=>"target_list", :controller=>"pages"}
#                                       pages GET    /pages(.:format)                                               {:action=>"index", :controller=>"pages"}
#                                             POST   /pages(.:format)                                               {:action=>"create", :controller=>"pages"}
#                                    new_page GET    /pages/new(.:format)                                           {:action=>"new", :controller=>"pages"}
#                                   edit_page GET    /pages/:id/edit(.:format)                                      {:action=>"edit", :controller=>"pages"}
#                                        page GET    /pages/:id(.:format)                                           {:action=>"show", :controller=>"pages"}
#                                             PUT    /pages/:id(.:format)                                           {:action=>"update", :controller=>"pages"}
#                                             DELETE /pages/:id(.:format)                                           {:action=>"destroy", :controller=>"pages"}
#                          select_task_filter        /task_filters/:id/select(.:format)                             {:action=>"select", :controller=>"task_filters"}
#                         recent_task_filters GET    /task_filters/recent(.:format)                                 {:action=>"recent", :controller=>"task_filters"}
#                          reset_task_filters GET    /task_filters/reset(.:format)                                  {:action=>"reset", :controller=>"task_filters"}
#                         search_task_filters GET    /task_filters/search(.:format)                                 {:action=>"search", :controller=>"task_filters"}
#          update_current_filter_task_filters GET    /task_filters/update_current_filter(.:format)                  {:action=>"update_current_filter", :controller=>"task_filters"}
#         set_single_task_filter_task_filters GET    /task_filters/set_single_task_filter(.:format)                 {:action=>"set_single_task_filter", :controller=>"task_filters"}
#                                task_filters GET    /task_filters(.:format)                                        {:action=>"index", :controller=>"task_filters"}
#                                             POST   /task_filters(.:format)                                        {:action=>"create", :controller=>"task_filters"}
#                             new_task_filter GET    /task_filters/new(.:format)                                    {:action=>"new", :controller=>"task_filters"}
#                            edit_task_filter GET    /task_filters/:id/edit(.:format)                               {:action=>"edit", :controller=>"task_filters"}
#                                 task_filter GET    /task_filters/:id(.:format)                                    {:action=>"show", :controller=>"task_filters"}
#                                             PUT    /task_filters/:id(.:format)                                    {:action=>"update", :controller=>"task_filters"}
#                                             DELETE /task_filters/:id(.:format)                                    {:action=>"destroy", :controller=>"task_filters"}
#                                        home        /forums/index(.:format)                                        {:controller=>"forums", :action=>"index"}
#                                 forum_posts GET    /forums/:forum_id/posts(.:format)                              {:action=>"index", :controller=>"posts"}
#                                             POST   /forums/:forum_id/posts(.:format)                              {:action=>"create", :controller=>"posts"}
#                              new_forum_post GET    /forums/:forum_id/posts/new(.:format)                          {:action=>"new", :controller=>"posts"}
#                             edit_forum_post GET    /forums/:forum_id/posts/:id/edit(.:format)                     {:action=>"edit", :controller=>"posts"}
#                                  forum_post GET    /forums/:forum_id/posts/:id(.:format)                          {:action=>"show", :controller=>"posts"}
#                                             PUT    /forums/:forum_id/posts/:id(.:format)                          {:action=>"update", :controller=>"posts"}
#                                             DELETE /forums/:forum_id/posts/:id(.:format)                          {:action=>"destroy", :controller=>"posts"}
#                                      forums GET    /forums(.:format)                                              {:action=>"index", :controller=>"forums"}
#                                             POST   /forums(.:format)                                              {:action=>"create", :controller=>"forums"}
#                                   new_forum GET    /forums/new(.:format)                                          {:action=>"new", :controller=>"forums"}
#                                  edit_forum GET    /forums/:id/edit(.:format)                                     {:action=>"edit", :controller=>"forums"}
#                                       forum GET    /forums/:id(.:format)                                          {:action=>"show", :controller=>"forums"}
#                                             PUT    /forums/:id(.:format)                                          {:action=>"update", :controller=>"forums"}
#                                             DELETE /forums/:id(.:format)                                          {:action=>"destroy", :controller=>"forums"}
#                                      topics GET    /forums/:forum_id/topics(.:format)                             {:action=>"index", :controller=>"topics"}
#                                             POST   /forums/:forum_id/topics(.:format)                             {:action=>"create", :controller=>"topics"}
#                                   new_topic GET    /forums/:forum_id/topics/new(.:format)                         {:action=>"new", :controller=>"topics"}
#                                  edit_topic GET    /forums/:forum_id/topics/:id/edit(.:format)                    {:action=>"edit", :controller=>"topics"}
#                                       topic GET    /forums/:forum_id/topics/:id(.:format)                         {:action=>"show", :controller=>"topics"}
#                                             PUT    /forums/:forum_id/topics/:id(.:format)                         {:action=>"update", :controller=>"topics"}
#                                             DELETE /forums/:forum_id/topics/:id(.:format)                         {:action=>"destroy", :controller=>"topics"}
#                                 monitorship POST   /forums/:forum_id/monitorship(.:format)                        {:action=>"create", :controller=>"monitorships"}
#                                             DELETE /forums/:forum_id/monitorship(.:format)                        {:action=>"destroy", :controller=>"monitorships"}
#                                       posts GET    /forums/:forum_id/topics/:topic_id/posts(.:format)             {:action=>"index", :controller=>"posts"}
#                                             POST   /forums/:forum_id/topics/:topic_id/posts(.:format)             {:action=>"create", :controller=>"posts"}
#                                    new_post GET    /forums/:forum_id/topics/:topic_id/posts/new(.:format)         {:action=>"new", :controller=>"posts"}
#                                   edit_post GET    /forums/:forum_id/topics/:topic_id/posts/:id/edit(.:format)    {:action=>"edit", :controller=>"posts"}
#                                        post GET    /forums/:forum_id/topics/:topic_id/posts/:id(.:format)         {:action=>"show", :controller=>"posts"}
#                                             PUT    /forums/:forum_id/topics/:topic_id/posts/:id(.:format)         {:action=>"update", :controller=>"posts"}
#                                             DELETE /forums/:forum_id/topics/:topic_id/posts/:id(.:format)         {:action=>"destroy", :controller=>"posts"}
#                           topic_monitorship POST   /forums/:forum_id/topics/:topic_id/topic_monitorship(.:format) {:action=>"create", :controller=>"monitorships"}
#                                             DELETE /forums/:forum_id/topics/:topic_id/topic_monitorship(.:format) {:action=>"destroy", :controller=>"monitorships"}
#                            search_all_posts GET    /posts/search(.:format)                                        {:action=>"search", :controller=>"posts"}
#                                   all_posts GET    /posts(.:format)                                               {:action=>"index", :controller=>"posts"}
#                                             POST   /posts(.:format)                                               {:action=>"create", :controller=>"posts"}
#                                new_all_post GET    /posts/new(.:format)                                           {:action=>"new", :controller=>"posts"}
#                               edit_all_post GET    /posts/:id/edit(.:format)                                      {:action=>"edit", :controller=>"posts"}
#                                    all_post GET    /posts/:id(.:format)                                           {:action=>"show", :controller=>"posts"}
#                                             PUT    /posts/:id(.:format)                                           {:action=>"update", :controller=>"posts"}
#                                             DELETE /posts/:id(.:format)                                           {:action=>"destroy", :controller=>"posts"}
#                            toggle_done_todo        /todos/:id/toggle_done(.:format)                               {:action=>"toggle_done", :controller=>"todos"}
#                                       todos GET    /todos(.:format)                                               {:action=>"index", :controller=>"todos"}
#                                             POST   /todos(.:format)                                               {:action=>"create", :controller=>"todos"}
#                                    new_todo GET    /todos/new(.:format)                                           {:action=>"new", :controller=>"todos"}
#                                   edit_todo GET    /todos/:id/edit(.:format)                                      {:action=>"edit", :controller=>"todos"}
#                                        todo GET    /todos/:id(.:format)                                           {:action=>"show", :controller=>"todos"}
#                                             PUT    /todos/:id(.:format)                                           {:action=>"update", :controller=>"todos"}
#                                             DELETE /todos/:id(.:format)                                           {:action=>"destroy", :controller=>"todos"}
#                                   work_logs GET    /work_logs(.:format)                                           {:action=>"index", :controller=>"work_logs"}
#                                             POST   /work_logs(.:format)                                           {:action=>"create", :controller=>"work_logs"}
#                                new_work_log GET    /work_logs/new(.:format)                                       {:action=>"new", :controller=>"work_logs"}
#                               edit_work_log GET    /work_logs/:id/edit(.:format)                                  {:action=>"edit", :controller=>"work_logs"}
#                                    work_log GET    /work_logs/:id(.:format)                                       {:action=>"show", :controller=>"work_logs"}
#                                             PUT    /work_logs/:id(.:format)                                       {:action=>"update", :controller=>"work_logs"}
#                                             DELETE /work_logs/:id(.:format)                                       {:action=>"destroy", :controller=>"work_logs"}
#                 auto_complete_for_tags_tags GET    /tags/auto_complete_for_tags(.:format)                         {:action=>"auto_complete_for_tags", :controller=>"tags"}
#                                        tags GET    /tags(.:format)                                                {:action=>"index", :controller=>"tags"}
#                                             POST   /tags(.:format)                                                {:action=>"create", :controller=>"tags"}
#                                     new_tag GET    /tags/new(.:format)                                            {:action=>"new", :controller=>"tags"}
#                                    edit_tag GET    /tags/:id/edit(.:format)                                       {:action=>"edit", :controller=>"tags"}
#                                         tag GET    /tags/:id(.:format)                                            {:action=>"show", :controller=>"tags"}
#                                             PUT    /tags/:id(.:format)                                            {:action=>"update", :controller=>"tags"}
#                                             DELETE /tags/:id(.:format)                                            {:action=>"destroy", :controller=>"tags"}
#                            start_work_index GET    /work/start(.:format)                                          {:action=>"start", :controller=>"work"}
#                             stop_work_index GET    /work/stop(.:format)                                           {:action=>"stop", :controller=>"work"}
#                           cancel_work_index GET    /work/cancel(.:format)                                         {:action=>"cancel", :controller=>"work"}
#                            pause_work_index GET    /work/pause(.:format)                                          {:action=>"pause", :controller=>"work"}
#                                  work_index GET    /work(.:format)                                                {:action=>"index", :controller=>"work"}
#                                             POST   /work(.:format)                                                {:action=>"create", :controller=>"work"}
#                                    new_work GET    /work/new(.:format)                                            {:action=>"new", :controller=>"work"}
#                                   edit_work GET    /work/:id/edit(.:format)                                       {:action=>"edit", :controller=>"work"}
#                                        work GET    /work/:id(.:format)                                            {:action=>"show", :controller=>"work"}
#                                             PUT    /work/:id(.:format)                                            {:action=>"update", :controller=>"work"}
#                                             DELETE /work/:id(.:format)                                            {:action=>"destroy", :controller=>"work"}
#                   formatted_monitored_posts        /users/:user_id/monitored.:format                              {:controller=>"posts", :action=>"monitored"}
#                             monitored_posts        /users/:user_id/monitored(.:format)                            {:controller=>"posts", :action=>"monitored"}
#                                  properties GET    /properties(.:format)                                          {:action=>"index", :controller=>"properties"}
#                                             POST   /properties(.:format)                                          {:action=>"create", :controller=>"properties"}
#                                new_property GET    /properties/new(.:format)                                      {:action=>"new", :controller=>"properties"}
#                               edit_property GET    /properties/:id/edit(.:format)                                 {:action=>"edit", :controller=>"properties"}
#                                    property GET    /properties/:id(.:format)                                      {:action=>"show", :controller=>"properties"}
#                                             PUT    /properties/:id(.:format)                                      {:action=>"update", :controller=>"properties"}
#                                             DELETE /properties/:id(.:format)                                      {:action=>"destroy", :controller=>"properties"}
#                                scm_projects GET    /scm_projects(.:format)                                        {:action=>"index", :controller=>"scm_projects"}
#                                             POST   /scm_projects(.:format)                                        {:action=>"create", :controller=>"scm_projects"}
#                             new_scm_project GET    /scm_projects/new(.:format)                                    {:action=>"new", :controller=>"scm_projects"}
#                            edit_scm_project GET    /scm_projects/:id/edit(.:format)                               {:action=>"edit", :controller=>"scm_projects"}
#                                 scm_project GET    /scm_projects/:id(.:format)                                    {:action=>"show", :controller=>"scm_projects"}
#                                             PUT    /scm_projects/:id(.:format)                                    {:action=>"update", :controller=>"scm_projects"}
#                                             DELETE /scm_projects/:id(.:format)                                    {:action=>"destroy", :controller=>"scm_projects"}
#                                    triggers GET    /triggers(.:format)                                            {:action=>"index", :controller=>"triggers"}
#                                             POST   /triggers(.:format)                                            {:action=>"create", :controller=>"triggers"}
#                                 new_trigger GET    /triggers/new(.:format)                                        {:action=>"new", :controller=>"triggers"}
#                                edit_trigger GET    /triggers/:id/edit(.:format)                                   {:action=>"edit", :controller=>"triggers"}
#                                     trigger GET    /triggers/:id(.:format)                                        {:action=>"show", :controller=>"triggers"}
#                                             PUT    /triggers/:id(.:format)                                        {:action=>"update", :controller=>"triggers"}
#                                             DELETE /triggers/:id(.:format)                                        {:action=>"destroy", :controller=>"triggers"}
#                                                    /api/scm/:provider/:secret_key(.:format)                       {:controller=>"scm_changesets", :action=>"create"}
#                                                    /:controller/service.wsdl(.:format)                            {:action=>"wsdl"}
#                                                    /:controller(/:action(/:id(.:format)))
