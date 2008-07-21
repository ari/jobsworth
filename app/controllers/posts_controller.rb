class PostsController < ApplicationController
  before_filter :find_post,      :except => [:index, :create, :monitored, :search]

  @@query_options = { :select => 'posts.*, topics.title as topic_title, forums.name as forum_name', :joins => 'inner join topics on posts.topic_id = topics.id inner join forums on topics.forum_id = forums.id', :order => 'posts.created_at desc', :page => 1 }

  def index
    conditions = []
    [:user_id, :forum_id, :topic_id].each { |attr| conditions << Post.send(:sanitize_sql, ["posts.#{attr} = ?", params[attr]]) if params[attr] }
    conditions << Post.send(:sanitize_sql, ["(forums.company_id IS NULL OR (forums.company_id = ? AND (forums.project_id IS NULL OR forums.project_id IN (#{current_project_ids}))))", current_user.company_id])
    conditions = conditions.any? ? conditions.collect { |c| "(#{c})" }.join(' AND ') : nil
    @posts = Post.paginate(@@query_options.merge(:conditions => conditions))
    @users = User.find(:all, :select => 'distinct *', :conditions => ['id in (?)', @posts.collect{ |post| post.user_id }.uniq]).index_by{ |post| post.id }
    render_posts_or_xml
  end

  def search
    conditions = params[:q].blank? ? Post.send(:sanitize_sql, ["(forums.company_id IS NULL OR (forums.company_id = ? AND (forums.project_id IS NULL OR forums.project_id IN (#{current_project_ids}))))", current_user.company_id]) : Post.send(:sanitize_sql, ["(forums.company_id IS NULL OR (forums.company_id = ? AND (forums.project_id IS NULL OR forums.project_id IN (#{current_project_ids})))) AND LOWER(posts.body) LIKE ?", current_user.company_id, "%#{params[:q]}%"])
    logger.info("conditions = [#{conditions.inspect}]")
    @posts = Post.paginate(@@query_options.merge(:conditions => conditions))
    @users = User.find(:all, :select => 'distinct *', :conditions => ['id in (?)', @posts.collect{ |post| post.user_id}.uniq]).index_by{ |post| post.id }
    render_posts_or_xml :index
  end

  def monitored
    @user = User.find params[:user_id]
    options = @@query_options.merge(:conditions => ['monitorships.user_id = ? and posts.user_id != ? and monitorships.active = ?', params[:user_id], @user.id, true])
    options[:joins] += ' inner join monitorships on monitorships.topic_id = topics.id'
    @posts = Post.paginate(options)
    render_posts_or_xml
  end

  def show
    respond_to do |format|
      format.html { redirect_to topic_path(@post.forum_id, @post.topic_id) }
      format.xml  { render :xml => @post.to_xml }
    end
  end

  def create
    @topic = Topic.find_by_id_and_forum_id(params[:topic_id],params[:forum_id], :include => :forum)
    if @topic.locked?
      respond_to do |format|
        format.html do
          flash[:notice] = 'This topic is locked.'
          redirect_to(topic_path(:forum_id => params[:forum_id], :id => params[:topic_id]))
        end
        format.xml do
          render :text => 'This topic is locked.', :status => 400
        end
      end
      return
    end
    @forum = @topic.forum
    @post  = @topic.posts.build(params[:post])
    @post.user = current_user
    @post.save!

    # Send notification emails to thread participants / monitors
    if @topic.posts.size > 0
      Notifications::deliver_forum_reply(current_user, @post) rescue nil
    end

    respond_to do |format|
      format.html do
        redirect_to topic_path(:forum_id => params[:forum_id], :id => params[:topic_id], :anchor => @post.dom_id, :page => params[:page] || '1')
      end
      format.xml { head :created, :location => formatted_post_url(:forum_id => params[:forum_id], :topic_id => params[:topic_id], :id => @post, :format => :xml) }
    end
  rescue ActiveRecord::RecordInvalid
    flash[:bad_reply] = 'Please post something at least...'
    respond_to do |format|
      format.html do
        redirect_to topic_path(:forum_id => params[:forum_id], :id => params[:topic_id], :anchor => 'reply-form', :page => params[:page] || '1')
      end
      format.xml { render :xml => @post.errors.to_xml, :status => 400 }
    end
  end

  def edit
  end

  def update
    @post.attributes = params[:post]
    @post.save!
  rescue ActiveRecord::RecordInvalid
    flash[:bad_reply] = 'An error occurred'
  ensure
    respond_to do |format|
      format.html do
        redirect_to topic_path(:forum_id => params[:forum_id], :id => params[:topic_id], :anchor => @post.dom_id, :page => params[:page] || '1')
      end
      format.js
      format.xml { head 200 }
    end
  end

  def destroy
    @post.destroy
    flash[:notice] = "Post of '#{CGI::escapeHTML(@post.topic.title)}' was deleted."
    # check for posts_count == 1 because its cached and counting the currently deleted post
    @post.topic.destroy and redirect_to forum_path(params[:forum_id]) if @post.topic.posts_count == 1
    respond_to do |format|
      format.html do
        redirect_to topic_path(:forum_id => params[:forum_id], :id => params[:topic_id], :page => params[:page]) unless performed?
      end
      format.xml { head 200 }
    end
  end

  protected
    def authorized?
      action_name == 'create' || @post.editable_by?(current_user)
    end

    def find_post
      @post = Post.find_by_id_and_topic_id_and_forum_id(params[:id], params[:topic_id], params[:forum_id]) || raise(ActiveRecord::RecordNotFound)
    end

    def render_posts_or_xml(template_name = action_name)
      respond_to do |format|
        format.html { render :action => "#{template_name}.rhtml" }
        format.rss  { render :action => "#{template_name}.rxml", :layout => false }
        format.xml  { render :xml => @posts.to_xml }
      end
    end
end
