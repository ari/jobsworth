class NewsItemsController < ApplicationController
  before_filter :authorize_user_is_admin

  def index
    @news = paginate(NewsItem.scoped)
  end

  def new
    @news = NewsItem.new
  end

  def create
    @news = NewsItem.create(params[:news])
    
    if @news.valid?
      flash[:success] = 'NewsItem was successfully created.'
      redirect_to news_items_path
    else
      flash[:error] = @news.errors.full_messages.join(". ")
      render :new
    end
  end

  def edit
    @news = NewsItem.find(params[:id])
  end

  def update
    @news = NewsItem.find(params[:id])

    if @news.update_attributes(params[:news])
      flash[:success] = 'NewsItem was successfully updated.'
      redirect_to news_items_path
    else
      flash[:error] = @news.errors.full_messages.join(". ")
      render :edit
    end
  end

  def destroy
    if NewsItem.find(params[:id]).destroy
      flash[:success] = 'NewsItem was successfully deleted.'
    else
      flash[:error] = 'Delete failed.'
    end
    redirect_to news_items_path
  end
end
