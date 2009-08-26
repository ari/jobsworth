class TopicsController < ApplicationController
  before_filter :find_forum_and_topic, :except => :index
#  before_filter :update_last_seen_at, :only => :show

  def index
    respond_to do |format|
      format.html { redirect_to forum_path(params[:forum_id]) }
    end
  end

  def new
    @topic = Topic.new
  end

  def show
    respond_to do |format|
      format.html do
        # keep track of when we last viewed this topic for activity indicators
        (session[:topics] ||= {})[@topic.id] = Time.now.utc if logged_in?
        # authors of topics don't get counted towards total hits
        @topic.hit! unless @topic.user == current_user
        @posts = Post.paginate(:order => 'posts.created_at', :include => :user, :conditions => ['posts.topic_id = ?', params[:id]], :page => params[:page] || 1)
        @post   = Post.new
      end
    end
  end

  def create
    # this is icky - move the topic/first post workings into the topic model?
    Topic.transaction do
      @topic  = @forum.topics.build(params[:topic])
      assign_protected
      @post   = @topic.posts.build(params[:topic])
      @post.topic=@topic
      @post.user = current_user
      # only save topic if post is valid so in the view topic will be a new record if there was an error
      @topic.body = @post.body # incase save fails and we go back to the form
      @topic.save! if @post.valid?
      @post.save!

      Notifications::deliver_forum_post(current_user, @post) rescue nil
    end
    respond_to do |format|
      format.html { redirect_to topic_path(@forum, @topic) }
    end
  end

  def update
    if @topic.user_id != current_user.id && !admin? && !current_user.moderator_of?(@topic.forum)
      redirect_to topic_path(@forum, @topic)
      return
    end
    @topic.attributes = params[:topic]
    assign_protected
    @topic.save!
    respond_to do |format|
      format.html { redirect_to topic_path(@forum, @topic) }
      format.xml  { head 200 }
    end
  end

  def destroy
    if current_user.id != @topic.user_id && !admin? && !current_user.moderator_of?(@topic.forum)
      redirect_to forums_path
      return
    end

    if current_user.admin < 2 && @topic.forum.company_id != current_user.company_id
      redirect_to forums_path
      return
    end

    @topic.destroy
    flash[:notice] = "Topic '#{CGI::escapeHTML(@topic.title)}' was deleted."
    respond_to do |format|
      format.html { redirect_to forum_path(@forum) }
      format.xml  { head 200 }
    end
  end

  protected
    def assign_protected
      @topic.user     = current_user if @topic.new_record?
      # admins and moderators can sticky and lock topics
      return unless admin? or current_user.moderator_of?(@topic.forum)
      @topic.sticky, @topic.locked = params[:topic][:sticky], params[:topic][:locked]
      # only admins can move
      return unless admin?
      @topic.forum_id = params[:topic][:forum_id] if params[:topic][:forum_id]
    end

    def find_forum_and_topic
      @forum = Forum.find(params[:forum_id], :conditions => ["company_id IS NULL OR (company_id = ? AND (project_id IS NULL OR project_id IN (#{current_project_ids})))", current_user.company_id])
      @topic = @forum.topics.find(params[:id]) if params[:id]
    end

    def authorized?
      %w(new create).include?(action_name) || @topic.editable_by?(current_user)
    end
end
