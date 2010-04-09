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
# Generated on 08 Apr 2010 19:22
#
#                                    triggers GET    /triggers(.:format)                                                 {:controller=>"triggers", :action=>"index"}
#                                             POST   /triggers(.:format)                                                 {:controller=>"triggers", :action=>"create"}
#                                 new_trigger GET    /triggers/new(.:format)                                             {:controller=>"triggers", :action=>"new"}
#                                edit_trigger GET    /triggers/:id/edit(.:format)                                        {:controller=>"triggers", :action=>"edit"}
#                                     trigger GET    /triggers/:id(.:format)                                             {:controller=>"triggers", :action=>"show"}
#                                             PUT    /triggers/:id(.:format)                                             {:controller=>"triggers", :action=>"update"}
#                                             DELETE /triggers/:id(.:format)                                             {:controller=>"triggers", :action=>"destroy"}
#                                                    /                                                                   {:controller=>"login", :action=>"login"}
#                                                    /signup                                                             {:controller=>"login", :action=>"signup"}
#                                                    /screenshots                                                        {:controller=>"login", :action=>"screenshots"}
#                                                    /policy                                                             {:controller=>"login", :action=>"policy"}
#                                                    /terms                                                              {:controller=>"login", :action=>"terms"}
#                                                    /about                                                              {:controller=>"login", :action=>"about"}
#                                        home        /forums/index                                                       {:controller=>"forums", :action=>"index"}
# auto_complete_for_resource_parent_resources GET    /resources/auto_complete_for_resource_parent(.:format)              {:controller=>"resources", :action=>"auto_complete_for_resource_parent"}
#                        attributes_resources GET    /resources/attributes(.:format)                                     {:controller=>"resources", :action=>"attributes"}
#                                   resources GET    /resources(.:format)                                                {:controller=>"resources", :action=>"index"}
#                                             POST   /resources(.:format)                                                {:controller=>"resources", :action=>"create"}
#                                new_resource GET    /resources/new(.:format)                                            {:controller=>"resources", :action=>"new"}
#                               edit_resource GET    /resources/:id/edit(.:format)                                       {:controller=>"resources", :action=>"edit"}
#                      show_password_resource GET    /resources/:id/show_password(.:format)                              {:controller=>"resources", :action=>"show_password"}
#                                    resource GET    /resources/:id(.:format)                                            {:controller=>"resources", :action=>"show"}
#                                             PUT    /resources/:id(.:format)                                            {:controller=>"resources", :action=>"update"}
#                                             DELETE /resources/:id(.:format)                                            {:controller=>"resources", :action=>"destroy"}
#                    attribute_resource_types GET    /resource_types/attribute(.:format)                                 {:controller=>"resource_types", :action=>"attribute"}
#                              resource_types GET    /resource_types(.:format)                                           {:controller=>"resource_types", :action=>"index"}
#                                             POST   /resource_types(.:format)                                           {:controller=>"resource_types", :action=>"create"}
#                           new_resource_type GET    /resource_types/new(.:format)                                       {:controller=>"resource_types", :action=>"new"}
#                          edit_resource_type GET    /resource_types/:id/edit(.:format)                                  {:controller=>"resource_types", :action=>"edit"}
#                               resource_type GET    /resource_types/:id(.:format)                                       {:controller=>"resource_types", :action=>"show"}
#                                             PUT    /resource_types/:id(.:format)                                       {:controller=>"resource_types", :action=>"update"}
#                                             DELETE /resource_types/:id(.:format)                                       {:controller=>"resource_types", :action=>"destroy"}
#                        organizational_units GET    /organizational_units(.:format)                                     {:controller=>"organizational_units", :action=>"index"}
#                                             POST   /organizational_units(.:format)                                     {:controller=>"organizational_units", :action=>"create"}
#                     new_organizational_unit GET    /organizational_units/new(.:format)                                 {:controller=>"organizational_units", :action=>"new"}
#                    edit_organizational_unit GET    /organizational_units/:id/edit(.:format)                            {:controller=>"organizational_units", :action=>"edit"}
#                         organizational_unit GET    /organizational_units/:id(.:format)                                 {:controller=>"organizational_units", :action=>"show"}
#                                             PUT    /organizational_units/:id(.:format)                                 {:controller=>"organizational_units", :action=>"update"}
#                                             DELETE /organizational_units/:id(.:format)                                 {:controller=>"organizational_units", :action=>"destroy"}
#                           target_list_pages        /pages/target_list(.:format)                                        {:controller=>"pages", :action=>"target_list"}
#                                       pages GET    /pages(.:format)                                                    {:controller=>"pages", :action=>"index"}
#                                             POST   /pages(.:format)                                                    {:controller=>"pages", :action=>"create"}
#                                    new_page GET    /pages/new(.:format)                                                {:controller=>"pages", :action=>"new"}
#                                   edit_page GET    /pages/:id/edit(.:format)                                           {:controller=>"pages", :action=>"edit"}
#                                        page GET    /pages/:id(.:format)                                                {:controller=>"pages", :action=>"show"}
#                                             PUT    /pages/:id(.:format)                                                {:controller=>"pages", :action=>"update"}
#                                             DELETE /pages/:id(.:format)                                                {:controller=>"pages", :action=>"destroy"}
#          update_current_filter_task_filters        /task_filters/update_current_filter(.:format)                       {:controller=>"task_filters", :action=>"update_current_filter"}
#         set_single_task_filter_task_filters        /task_filters/set_single_task_filter(.:format)                      {:controller=>"task_filters", :action=>"set_single_task_filter"}
#                         search_task_filters        /task_filters/search(.:format)                                      {:controller=>"task_filters", :action=>"search"}
#                          reset_task_filters        /task_filters/reset(.:format)                                       {:controller=>"task_filters", :action=>"reset"}
#                                task_filters GET    /task_filters(.:format)                                             {:controller=>"task_filters", :action=>"index"}
#                                             POST   /task_filters(.:format)                                             {:controller=>"task_filters", :action=>"create"}
#                             new_task_filter GET    /task_filters/new(.:format)                                         {:controller=>"task_filters", :action=>"new"}
#                          select_task_filter        /task_filters/:id/select(.:format)                                  {:controller=>"task_filters", :action=>"select"}
#                            edit_task_filter GET    /task_filters/:id/edit(.:format)                                    {:controller=>"task_filters", :action=>"edit"}
#                                 task_filter GET    /task_filters/:id(.:format)                                         {:controller=>"task_filters", :action=>"show"}
#                                             PUT    /task_filters/:id(.:format)                                         {:controller=>"task_filters", :action=>"update"}
#                                             DELETE /task_filters/:id(.:format)                                         {:controller=>"task_filters", :action=>"destroy"}
#                                       posts GET    /forums/:forum_id/topics/:topic_id/posts(.:format)                  {:controller=>"posts", :action=>"index"}
#                                             POST   /forums/:forum_id/topics/:topic_id/posts(.:format)                  {:controller=>"posts", :action=>"create"}
#                                    new_post GET    /forums/:forum_id/topics/:topic_id/posts/new(.:format)              {:controller=>"posts", :action=>"new"}
#                                   edit_post GET    /forums/:forum_id/topics/:topic_id/posts/:id/edit(.:format)         {:controller=>"posts", :action=>"edit"}
#                                        post GET    /forums/:forum_id/topics/:topic_id/posts/:id(.:format)              {:controller=>"posts", :action=>"show"}
#                                             PUT    /forums/:forum_id/topics/:topic_id/posts/:id(.:format)              {:controller=>"posts", :action=>"update"}
#                                             DELETE /forums/:forum_id/topics/:topic_id/posts/:id(.:format)              {:controller=>"posts", :action=>"destroy"}
#                       new_topic_monitorship GET    /forums/:forum_id/topics/:topic_id/topic_monitorship/new(.:format)  {:controller=>"monitorships", :action=>"new"}
#                      edit_topic_monitorship GET    /forums/:forum_id/topics/:topic_id/topic_monitorship/edit(.:format) {:controller=>"monitorships", :action=>"edit"}
#                           topic_monitorship GET    /forums/:forum_id/topics/:topic_id/topic_monitorship(.:format)      {:controller=>"monitorships", :action=>"show"}
#                                             PUT    /forums/:forum_id/topics/:topic_id/topic_monitorship(.:format)      {:controller=>"monitorships", :action=>"update"}
#                                             DELETE /forums/:forum_id/topics/:topic_id/topic_monitorship(.:format)      {:controller=>"monitorships", :action=>"destroy"}
#                                             POST   /forums/:forum_id/topics/:topic_id/topic_monitorship(.:format)      {:controller=>"monitorships", :action=>"create"}
#                                      topics GET    /forums/:forum_id/topics(.:format)                                  {:controller=>"topics", :action=>"index"}
#                                             POST   /forums/:forum_id/topics(.:format)                                  {:controller=>"topics", :action=>"create"}
#                                   new_topic GET    /forums/:forum_id/topics/new(.:format)                              {:controller=>"topics", :action=>"new"}
#                                  edit_topic GET    /forums/:forum_id/topics/:id/edit(.:format)                         {:controller=>"topics", :action=>"edit"}
#                                       topic GET    /forums/:forum_id/topics/:id(.:format)                              {:controller=>"topics", :action=>"show"}
#                                             PUT    /forums/:forum_id/topics/:id(.:format)                              {:controller=>"topics", :action=>"update"}
#                                             DELETE /forums/:forum_id/topics/:id(.:format)                              {:controller=>"topics", :action=>"destroy"}
#                             new_monitorship GET    /forums/:forum_id/monitorship/new(.:format)                         {:controller=>"monitorships", :action=>"new"}
#                            edit_monitorship GET    /forums/:forum_id/monitorship/edit(.:format)                        {:controller=>"monitorships", :action=>"edit"}
#                                 monitorship GET    /forums/:forum_id/monitorship(.:format)                             {:controller=>"monitorships", :action=>"show"}
#                                             PUT    /forums/:forum_id/monitorship(.:format)                             {:controller=>"monitorships", :action=>"update"}
#                                             DELETE /forums/:forum_id/monitorship(.:format)                             {:controller=>"monitorships", :action=>"destroy"}
#                                             POST   /forums/:forum_id/monitorship(.:format)                             {:controller=>"monitorships", :action=>"create"}
#                                      forums GET    /forums(.:format)                                                   {:controller=>"forums", :action=>"index"}
#                                             POST   /forums(.:format)                                                   {:controller=>"forums", :action=>"create"}
#                                   new_forum GET    /forums/new(.:format)                                               {:controller=>"forums", :action=>"new"}
#                                  edit_forum GET    /forums/:id/edit(.:format)                                          {:controller=>"forums", :action=>"edit"}
#                                       forum GET    /forums/:id(.:format)                                               {:controller=>"forums", :action=>"show"}
#                                             PUT    /forums/:id(.:format)                                               {:controller=>"forums", :action=>"update"}
#                                             DELETE /forums/:id(.:format)                                               {:controller=>"forums", :action=>"destroy"}
#                            search_all_posts GET    /posts/search(.:format)                                             {:controller=>"posts", :action=>"search"}
#                                   all_posts GET    /posts(.:format)                                                    {:controller=>"posts", :action=>"index"}
#                                             POST   /posts(.:format)                                                    {:controller=>"posts", :action=>"create"}
#                                new_all_post GET    /posts/new(.:format)                                                {:controller=>"posts", :action=>"new"}
#                               edit_all_post GET    /posts/:id/edit(.:format)                                           {:controller=>"posts", :action=>"edit"}
#                                    all_post GET    /posts/:id(.:format)                                                {:controller=>"posts", :action=>"show"}
#                                             PUT    /posts/:id(.:format)                                                {:controller=>"posts", :action=>"update"}
#                                             DELETE /posts/:id(.:format)                                                {:controller=>"posts", :action=>"destroy"}
#                                       todos GET    /todos(.:format)                                                    {:controller=>"todos", :action=>"index"}
#                                             POST   /todos(.:format)                                                    {:controller=>"todos", :action=>"create"}
#                                    new_todo GET    /todos/new(.:format)                                                {:controller=>"todos", :action=>"new"}
#                                   edit_todo GET    /todos/:id/edit(.:format)                                           {:controller=>"todos", :action=>"edit"}
#                            toggle_done_todo POST   /todos/:id/toggle_done(.:format)                                    {:controller=>"todos", :action=>"toggle_done"}
#                                        todo GET    /todos/:id(.:format)                                                {:controller=>"todos", :action=>"show"}
#                                             PUT    /todos/:id(.:format)                                                {:controller=>"todos", :action=>"update"}
#                                             DELETE /todos/:id(.:format)                                                {:controller=>"todos", :action=>"destroy"}
#                                   work_logs GET    /work_logs(.:format)                                                {:controller=>"work_logs", :action=>"index"}
#                                             POST   /work_logs(.:format)                                                {:controller=>"work_logs", :action=>"create"}
#                                new_work_log GET    /work_logs/new(.:format)                                            {:controller=>"work_logs", :action=>"new"}
#                               edit_work_log GET    /work_logs/:id/edit(.:format)                                       {:controller=>"work_logs", :action=>"edit"}
#                                    work_log GET    /work_logs/:id(.:format)                                            {:controller=>"work_logs", :action=>"show"}
#                                             PUT    /work_logs/:id(.:format)                                            {:controller=>"work_logs", :action=>"update"}
#                                             DELETE /work_logs/:id(.:format)                                            {:controller=>"work_logs", :action=>"destroy"}
#                                        tags GET    /tags(.:format)                                                     {:controller=>"tags", :action=>"index"}
#                                             POST   /tags(.:format)                                                     {:controller=>"tags", :action=>"create"}
#                                     new_tag GET    /tags/new(.:format)                                                 {:controller=>"tags", :action=>"new"}
#                                    edit_tag GET    /tags/:id/edit(.:format)                                            {:controller=>"tags", :action=>"edit"}
#                                         tag GET    /tags/:id(.:format)                                                 {:controller=>"tags", :action=>"show"}
#                                             PUT    /tags/:id(.:format)                                                 {:controller=>"tags", :action=>"update"}
#                                             DELETE /tags/:id(.:format)                                                 {:controller=>"tags", :action=>"destroy"}
#                                  start_work        /work/start(.:format)                                               {:controller=>"work", :action=>"start"}
#                                  pause_work        /work/pause(.:format)                                               {:controller=>"work", :action=>"pause"}
#                                 cancel_work        /work/cancel(.:format)                                              {:controller=>"work", :action=>"cancel"}
#                                   stop_work        /work/stop(.:format)                                                {:controller=>"work", :action=>"stop"}
#                                  work_index GET    /work(.:format)                                                     {:controller=>"work", :action=>"index"}
#                                             POST   /work(.:format)                                                     {:controller=>"work", :action=>"create"}
#                                    new_work GET    /work/new(.:format)                                                 {:controller=>"work", :action=>"new"}
#                                   edit_work GET    /work/:id/edit(.:format)                                            {:controller=>"work", :action=>"edit"}
#                                        work GET    /work/:id(.:format)                                                 {:controller=>"work", :action=>"show"}
#                                             PUT    /work/:id(.:format)                                                 {:controller=>"work", :action=>"update"}
#                                             DELETE /work/:id(.:format)                                                 {:controller=>"work", :action=>"destroy"}
#                                  user_posts GET    /users/:user_id/posts(.:format)                                     {:controller=>"posts", :action=>"index"}
#                                             POST   /users/:user_id/posts(.:format)                                     {:controller=>"posts", :action=>"create"}
#                               new_user_post GET    /users/:user_id/posts/new(.:format)                                 {:controller=>"posts", :action=>"new"}
#                              edit_user_post GET    /users/:user_id/posts/:id/edit(.:format)                            {:controller=>"posts", :action=>"edit"}
#                                   user_post GET    /users/:user_id/posts/:id(.:format)                                 {:controller=>"posts", :action=>"show"}
#                                             PUT    /users/:user_id/posts/:id(.:format)                                 {:controller=>"posts", :action=>"update"}
#                                             DELETE /users/:user_id/posts/:id(.:format)                                 {:controller=>"posts", :action=>"destroy"}
#                                 forum_posts GET    /forums/:forum_id/posts(.:format)                                   {:controller=>"posts", :action=>"index"}
#                                             POST   /forums/:forum_id/posts(.:format)                                   {:controller=>"posts", :action=>"create"}
#                              new_forum_post GET    /forums/:forum_id/posts/new(.:format)                               {:controller=>"posts", :action=>"new"}
#                             edit_forum_post GET    /forums/:forum_id/posts/:id/edit(.:format)                          {:controller=>"posts", :action=>"edit"}
#                                  forum_post GET    /forums/:forum_id/posts/:id(.:format)                               {:controller=>"posts", :action=>"show"}
#                                             PUT    /forums/:forum_id/posts/:id(.:format)                               {:controller=>"posts", :action=>"update"}
#                                             DELETE /forums/:forum_id/posts/:id(.:format)                               {:controller=>"posts", :action=>"destroy"}
#                   formatted_monitored_posts        /users/:user_id/monitored(.:format)                                 {:controller=>"posts", :action=>"monitored"}
#                             monitored_posts        /users/:user_id/monitored                                           {:controller=>"posts", :action=>"monitored"}
#                                  properties GET    /properties(.:format)                                               {:controller=>"properties", :action=>"index"}
#                                             POST   /properties(.:format)                                               {:controller=>"properties", :action=>"create"}
#                                new_property GET    /properties/new(.:format)                                           {:controller=>"properties", :action=>"new"}
#                               edit_property GET    /properties/:id/edit(.:format)                                      {:controller=>"properties", :action=>"edit"}
#                                    property GET    /properties/:id(.:format)                                           {:controller=>"properties", :action=>"show"}
#                                             PUT    /properties/:id(.:format)                                           {:controller=>"properties", :action=>"update"}
#                                             DELETE /properties/:id(.:format)                                           {:controller=>"properties", :action=>"destroy"}
#                                                    /:controller/service.wsdl                                           {:action=>"wsdl"}
#                                                    /:controller/:action/:id(.:format)                                  
#                                                    /:controller/:action/:id                                            
# Loaded suite /opt/local/bin/rake
# Started
# 
# Finished in 0.000233 seconds.
# 
# 0 tests, 0 assertions, 0 failures, 0 errors
