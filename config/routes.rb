ActionController::Routing::Routes.draw do |map|
  map.resources :triggers


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
#== Route Map
# Generated on 20 Jan 2010 11:12
#
#                                    triggers GET    /triggers(.:format)                                                 {:action=>"index", :controller=>"triggers"}
#                                             POST   /triggers(.:format)                                                 {:action=>"create", :controller=>"triggers"}
#                                 new_trigger GET    /triggers/new(.:format)                                             {:action=>"new", :controller=>"triggers"}
#                                edit_trigger GET    /triggers/:id/edit(.:format)                                        {:action=>"edit", :controller=>"triggers"}
#                                     trigger GET    /triggers/:id(.:format)                                             {:action=>"show", :controller=>"triggers"}
#                                             PUT    /triggers/:id(.:format)                                             {:action=>"update", :controller=>"triggers"}
#                                             DELETE /triggers/:id(.:format)                                             {:action=>"destroy", :controller=>"triggers"}
#                                                    /                                                                   {:action=>"login", :controller=>"login"}
#                                                    /signup                                                             {:action=>"signup", :controller=>"login"}
#                                                    /screenshots                                                        {:action=>"screenshots", :controller=>"login"}
#                                                    /policy                                                             {:action=>"policy", :controller=>"login"}
#                                                    /terms                                                              {:action=>"terms", :controller=>"login"}
#                                                    /about                                                              {:action=>"about", :controller=>"login"}
#                                        home        /forums/index                                                       {:action=>"index", :controller=>"forums"}
#                        attributes_resources GET    /resources/attributes(.:format)                                     {:action=>"attributes", :controller=>"resources"}
# auto_complete_for_resource_parent_resources GET    /resources/auto_complete_for_resource_parent(.:format)              {:action=>"auto_complete_for_resource_parent", :controller=>"resources"}
#                                   resources GET    /resources(.:format)                                                {:action=>"index", :controller=>"resources"}
#                                             POST   /resources(.:format)                                                {:action=>"create", :controller=>"resources"}
#                                new_resource GET    /resources/new(.:format)                                            {:action=>"new", :controller=>"resources"}
#                               edit_resource GET    /resources/:id/edit(.:format)                                       {:action=>"edit", :controller=>"resources"}
#                      show_password_resource GET    /resources/:id/show_password(.:format)                              {:action=>"show_password", :controller=>"resources"}
#                                    resource GET    /resources/:id(.:format)                                            {:action=>"show", :controller=>"resources"}
#                                             PUT    /resources/:id(.:format)                                            {:action=>"update", :controller=>"resources"}
#                                             DELETE /resources/:id(.:format)                                            {:action=>"destroy", :controller=>"resources"}
#                    attribute_resource_types GET    /resource_types/attribute(.:format)                                 {:action=>"attribute", :controller=>"resource_types"}
#                              resource_types GET    /resource_types(.:format)                                           {:action=>"index", :controller=>"resource_types"}
#                                             POST   /resource_types(.:format)                                           {:action=>"create", :controller=>"resource_types"}
#                           new_resource_type GET    /resource_types/new(.:format)                                       {:action=>"new", :controller=>"resource_types"}
#                          edit_resource_type GET    /resource_types/:id/edit(.:format)                                  {:action=>"edit", :controller=>"resource_types"}
#                               resource_type GET    /resource_types/:id(.:format)                                       {:action=>"show", :controller=>"resource_types"}
#                                             PUT    /resource_types/:id(.:format)                                       {:action=>"update", :controller=>"resource_types"}
#                                             DELETE /resource_types/:id(.:format)                                       {:action=>"destroy", :controller=>"resource_types"}
#                        organizational_units GET    /organizational_units(.:format)                                     {:action=>"index", :controller=>"organizational_units"}
#                                             POST   /organizational_units(.:format)                                     {:action=>"create", :controller=>"organizational_units"}
#                     new_organizational_unit GET    /organizational_units/new(.:format)                                 {:action=>"new", :controller=>"organizational_units"}
#                    edit_organizational_unit GET    /organizational_units/:id/edit(.:format)                            {:action=>"edit", :controller=>"organizational_units"}
#                         organizational_unit GET    /organizational_units/:id(.:format)                                 {:action=>"show", :controller=>"organizational_units"}
#                                             PUT    /organizational_units/:id(.:format)                                 {:action=>"update", :controller=>"organizational_units"}
#                                             DELETE /organizational_units/:id(.:format)                                 {:action=>"destroy", :controller=>"organizational_units"}
#                           target_list_pages        /pages/target_list(.:format)                                        {:action=>"target_list", :controller=>"pages"}
#                                       pages GET    /pages(.:format)                                                    {:action=>"index", :controller=>"pages"}
#                                             POST   /pages(.:format)                                                    {:action=>"create", :controller=>"pages"}
#                                    new_page GET    /pages/new(.:format)                                                {:action=>"new", :controller=>"pages"}
#                                   edit_page GET    /pages/:id/edit(.:format)                                           {:action=>"edit", :controller=>"pages"}
#                                        page GET    /pages/:id(.:format)                                                {:action=>"show", :controller=>"pages"}
#                                             PUT    /pages/:id(.:format)                                                {:action=>"update", :controller=>"pages"}
#                                             DELETE /pages/:id(.:format)                                                {:action=>"destroy", :controller=>"pages"}
#         set_single_task_filter_task_filters        /task_filters/set_single_task_filter(.:format)                      {:action=>"set_single_task_filter", :controller=>"task_filters"}
#          update_current_filter_task_filters        /task_filters/update_current_filter(.:format)                       {:action=>"update_current_filter", :controller=>"task_filters"}
#                         search_task_filters        /task_filters/search(.:format)                                      {:action=>"search", :controller=>"task_filters"}
#                          reset_task_filters        /task_filters/reset(.:format)                                       {:action=>"reset", :controller=>"task_filters"}
#                                task_filters GET    /task_filters(.:format)                                             {:action=>"index", :controller=>"task_filters"}
#                                             POST   /task_filters(.:format)                                             {:action=>"create", :controller=>"task_filters"}
#                             new_task_filter GET    /task_filters/new(.:format)                                         {:action=>"new", :controller=>"task_filters"}
#                          select_task_filter        /task_filters/:id/select(.:format)                                  {:action=>"select", :controller=>"task_filters"}
#                            edit_task_filter GET    /task_filters/:id/edit(.:format)                                    {:action=>"edit", :controller=>"task_filters"}
#                                 task_filter GET    /task_filters/:id(.:format)                                         {:action=>"show", :controller=>"task_filters"}
#                                             PUT    /task_filters/:id(.:format)                                         {:action=>"update", :controller=>"task_filters"}
#                                             DELETE /task_filters/:id(.:format)                                         {:action=>"destroy", :controller=>"task_filters"}
#                                       posts GET    /forums/:forum_id/topics/:topic_id/posts(.:format)                  {:action=>"index", :controller=>"posts"}
#                                             POST   /forums/:forum_id/topics/:topic_id/posts(.:format)                  {:action=>"create", :controller=>"posts"}
#                                    new_post GET    /forums/:forum_id/topics/:topic_id/posts/new(.:format)              {:action=>"new", :controller=>"posts"}
#                                   edit_post GET    /forums/:forum_id/topics/:topic_id/posts/:id/edit(.:format)         {:action=>"edit", :controller=>"posts"}
#                                        post GET    /forums/:forum_id/topics/:topic_id/posts/:id(.:format)              {:action=>"show", :controller=>"posts"}
#                                             PUT    /forums/:forum_id/topics/:topic_id/posts/:id(.:format)              {:action=>"update", :controller=>"posts"}
#                                             DELETE /forums/:forum_id/topics/:topic_id/posts/:id(.:format)              {:action=>"destroy", :controller=>"posts"}
#                       new_topic_monitorship GET    /forums/:forum_id/topics/:topic_id/topic_monitorship/new(.:format)  {:action=>"new", :controller=>"monitorships"}
#                      edit_topic_monitorship GET    /forums/:forum_id/topics/:topic_id/topic_monitorship/edit(.:format) {:action=>"edit", :controller=>"monitorships"}
#                           topic_monitorship GET    /forums/:forum_id/topics/:topic_id/topic_monitorship(.:format)      {:action=>"show", :controller=>"monitorships"}
#                                             PUT    /forums/:forum_id/topics/:topic_id/topic_monitorship(.:format)      {:action=>"update", :controller=>"monitorships"}
#                                             DELETE /forums/:forum_id/topics/:topic_id/topic_monitorship(.:format)      {:action=>"destroy", :controller=>"monitorships"}
#                                             POST   /forums/:forum_id/topics/:topic_id/topic_monitorship(.:format)      {:action=>"create", :controller=>"monitorships"}
#                                      topics GET    /forums/:forum_id/topics(.:format)                                  {:action=>"index", :controller=>"topics"}
#                                             POST   /forums/:forum_id/topics(.:format)                                  {:action=>"create", :controller=>"topics"}
#                                   new_topic GET    /forums/:forum_id/topics/new(.:format)                              {:action=>"new", :controller=>"topics"}
#                                  edit_topic GET    /forums/:forum_id/topics/:id/edit(.:format)                         {:action=>"edit", :controller=>"topics"}
#                                       topic GET    /forums/:forum_id/topics/:id(.:format)                              {:action=>"show", :controller=>"topics"}
#                                             PUT    /forums/:forum_id/topics/:id(.:format)                              {:action=>"update", :controller=>"topics"}
#                                             DELETE /forums/:forum_id/topics/:id(.:format)                              {:action=>"destroy", :controller=>"topics"}
#                             new_monitorship GET    /forums/:forum_id/monitorship/new(.:format)                         {:action=>"new", :controller=>"monitorships"}
#                            edit_monitorship GET    /forums/:forum_id/monitorship/edit(.:format)                        {:action=>"edit", :controller=>"monitorships"}
#                                 monitorship GET    /forums/:forum_id/monitorship(.:format)                             {:action=>"show", :controller=>"monitorships"}
#                                             PUT    /forums/:forum_id/monitorship(.:format)                             {:action=>"update", :controller=>"monitorships"}
#                                             DELETE /forums/:forum_id/monitorship(.:format)                             {:action=>"destroy", :controller=>"monitorships"}
#                                             POST   /forums/:forum_id/monitorship(.:format)                             {:action=>"create", :controller=>"monitorships"}
#                                      forums GET    /forums(.:format)                                                   {:action=>"index", :controller=>"forums"}
#                                             POST   /forums(.:format)                                                   {:action=>"create", :controller=>"forums"}
#                                   new_forum GET    /forums/new(.:format)                                               {:action=>"new", :controller=>"forums"}
#                                  edit_forum GET    /forums/:id/edit(.:format)                                          {:action=>"edit", :controller=>"forums"}
#                                       forum GET    /forums/:id(.:format)                                               {:action=>"show", :controller=>"forums"}
#                                             PUT    /forums/:id(.:format)                                               {:action=>"update", :controller=>"forums"}
#                                             DELETE /forums/:id(.:format)                                               {:action=>"destroy", :controller=>"forums"}
#                            search_all_posts GET    /posts/search(.:format)                                             {:action=>"search", :controller=>"posts"}
#                                   all_posts GET    /posts(.:format)                                                    {:action=>"index", :controller=>"posts"}
#                                             POST   /posts(.:format)                                                    {:action=>"create", :controller=>"posts"}
#                                new_all_post GET    /posts/new(.:format)                                                {:action=>"new", :controller=>"posts"}
#                               edit_all_post GET    /posts/:id/edit(.:format)                                           {:action=>"edit", :controller=>"posts"}
#                                    all_post GET    /posts/:id(.:format)                                                {:action=>"show", :controller=>"posts"}
#                                             PUT    /posts/:id(.:format)                                                {:action=>"update", :controller=>"posts"}
#                                             DELETE /posts/:id(.:format)                                                {:action=>"destroy", :controller=>"posts"}
#                                       todos GET    /todos(.:format)                                                    {:action=>"index", :controller=>"todos"}
#                                             POST   /todos(.:format)                                                    {:action=>"create", :controller=>"todos"}
#                                    new_todo GET    /todos/new(.:format)                                                {:action=>"new", :controller=>"todos"}
#                                   edit_todo GET    /todos/:id/edit(.:format)                                           {:action=>"edit", :controller=>"todos"}
#                            toggle_done_todo POST   /todos/:id/toggle_done(.:format)                                    {:action=>"toggle_done", :controller=>"todos"}
#                                        todo GET    /todos/:id(.:format)                                                {:action=>"show", :controller=>"todos"}
#                                             PUT    /todos/:id(.:format)                                                {:action=>"update", :controller=>"todos"}
#                                             DELETE /todos/:id(.:format)                                                {:action=>"destroy", :controller=>"todos"}
#                                   work_logs GET    /work_logs(.:format)                                                {:action=>"index", :controller=>"work_logs"}
#                                             POST   /work_logs(.:format)                                                {:action=>"create", :controller=>"work_logs"}
#                                new_work_log GET    /work_logs/new(.:format)                                            {:action=>"new", :controller=>"work_logs"}
#                               edit_work_log GET    /work_logs/:id/edit(.:format)                                       {:action=>"edit", :controller=>"work_logs"}
#                                    work_log GET    /work_logs/:id(.:format)                                            {:action=>"show", :controller=>"work_logs"}
#                                             PUT    /work_logs/:id(.:format)                                            {:action=>"update", :controller=>"work_logs"}
#                                             DELETE /work_logs/:id(.:format)                                            {:action=>"destroy", :controller=>"work_logs"}
#                                        tags GET    /tags(.:format)                                                     {:action=>"index", :controller=>"tags"}
#                                             POST   /tags(.:format)                                                     {:action=>"create", :controller=>"tags"}
#                                     new_tag GET    /tags/new(.:format)                                                 {:action=>"new", :controller=>"tags"}
#                                    edit_tag GET    /tags/:id/edit(.:format)                                            {:action=>"edit", :controller=>"tags"}
#                                         tag GET    /tags/:id(.:format)                                                 {:action=>"show", :controller=>"tags"}
#                                             PUT    /tags/:id(.:format)                                                 {:action=>"update", :controller=>"tags"}
#                                             DELETE /tags/:id(.:format)                                                 {:action=>"destroy", :controller=>"tags"}
#                                  start_work        /work/start(.:format)                                               {:action=>"start", :controller=>"work"}
#                                  pause_work        /work/pause(.:format)                                               {:action=>"pause", :controller=>"work"}
#                                   stop_work        /work/stop(.:format)                                                {:action=>"stop", :controller=>"work"}
#                                 cancel_work        /work/cancel(.:format)                                              {:action=>"cancel", :controller=>"work"}
#                                  work_index GET    /work(.:format)                                                     {:action=>"index", :controller=>"work"}
#                                             POST   /work(.:format)                                                     {:action=>"create", :controller=>"work"}
#                                    new_work GET    /work/new(.:format)                                                 {:action=>"new", :controller=>"work"}
#                                   edit_work GET    /work/:id/edit(.:format)                                            {:action=>"edit", :controller=>"work"}
#                                        work GET    /work/:id(.:format)                                                 {:action=>"show", :controller=>"work"}
#                                             PUT    /work/:id(.:format)                                                 {:action=>"update", :controller=>"work"}
#                                             DELETE /work/:id(.:format)                                                 {:action=>"destroy", :controller=>"work"}
#                                  user_posts GET    /users/:user_id/posts(.:format)                                     {:action=>"index", :controller=>"posts"}
#                                             POST   /users/:user_id/posts(.:format)                                     {:action=>"create", :controller=>"posts"}
#                               new_user_post GET    /users/:user_id/posts/new(.:format)                                 {:action=>"new", :controller=>"posts"}
#                              edit_user_post GET    /users/:user_id/posts/:id/edit(.:format)                            {:action=>"edit", :controller=>"posts"}
#                                   user_post GET    /users/:user_id/posts/:id(.:format)                                 {:action=>"show", :controller=>"posts"}
#                                             PUT    /users/:user_id/posts/:id(.:format)                                 {:action=>"update", :controller=>"posts"}
#                                             DELETE /users/:user_id/posts/:id(.:format)                                 {:action=>"destroy", :controller=>"posts"}
#                                 forum_posts GET    /forums/:forum_id/posts(.:format)                                   {:action=>"index", :controller=>"posts"}
#                                             POST   /forums/:forum_id/posts(.:format)                                   {:action=>"create", :controller=>"posts"}
#                              new_forum_post GET    /forums/:forum_id/posts/new(.:format)                               {:action=>"new", :controller=>"posts"}
#                             edit_forum_post GET    /forums/:forum_id/posts/:id/edit(.:format)                          {:action=>"edit", :controller=>"posts"}
#                                  forum_post GET    /forums/:forum_id/posts/:id(.:format)                               {:action=>"show", :controller=>"posts"}
#                                             PUT    /forums/:forum_id/posts/:id(.:format)                               {:action=>"update", :controller=>"posts"}
#                                             DELETE /forums/:forum_id/posts/:id(.:format)                               {:action=>"destroy", :controller=>"posts"}
#                   formatted_monitored_posts        /users/:user_id/monitored(.:format)                                 {:action=>"monitored", :controller=>"posts"}
#                             monitored_posts        /users/:user_id/monitored                                           {:action=>"monitored", :controller=>"posts"}
#                                  properties GET    /properties(.:format)                                               {:action=>"index", :controller=>"properties"}
#                                             POST   /properties(.:format)                                               {:action=>"create", :controller=>"properties"}
#                                new_property GET    /properties/new(.:format)                                           {:action=>"new", :controller=>"properties"}
#                               edit_property GET    /properties/:id/edit(.:format)                                      {:action=>"edit", :controller=>"properties"}
#                                    property GET    /properties/:id(.:format)                                           {:action=>"show", :controller=>"properties"}
#                                             PUT    /properties/:id(.:format)                                           {:action=>"update", :controller=>"properties"}
#                                             DELETE /properties/:id(.:format)                                           {:action=>"destroy", :controller=>"properties"}
#                                                    /:controller/service.wsdl                                           {:action=>"wsdl"}
#                                                    /:controller/:action/:id(.:format)                                  
#                                                    /:controller/:action/:id                                            
# Loaded suite /opt/local/bin/rake
# Started
# 
# Finished in 0.000237 seconds.
# 
# 0 tests, 0 assertions, 0 failures, 0 errors
