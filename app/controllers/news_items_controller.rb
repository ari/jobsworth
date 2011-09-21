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
      flash['notice'] = 'NewsItem was successfully created.'
      redirect_to news_items_path
    else
      render :new
    end
  end

  def edit
    @news = NewsItem.find(params[:id])
  end

  def update
    @news = NewsItem.find(params[:id])

    if @news.update_attributes(params[:news])
      flash['notice'] = 'NewsItem was successfully updated.'
      redirect_to news_items_path
    else
      render :edit
    end
  end

  def destroy
    NewsItem.find(params[:id]).destroy
    flash['notice'] = 'NewsItem was successfully deleted.'
    redirect_to news_items_path
  end
end
