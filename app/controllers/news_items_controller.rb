class NewsItemsController < ApplicationController

  before_filter :authorize_user_is_admin

  layout 'admin'

  def index
    @news = current_user.company.news_items.paginate(:page => params[:page], :per_page => 10)
  end

  def new
    @news = NewsItem.new
  end

  def create
    @news = NewsItem.create(news_item_params)
    @news.company = current_user.company

    if @news.save
      flash[:success] = t('flash.notice.model_created', model: NewsItem.model_name.human)
      redirect_to news_items_path
    else
      flash[:error] = @news.errors.full_messages.join('. ')
      render :new
    end
  end

  def edit
    @news = current_user.company.news_items.find(params[:id])
  end

  def update
    @news = current_user.company.news_items.find(params[:id])

    if @news.update_attributes(news_item_params)
      flash[:success] = t('flash.notice.model_updated', model: NewsItem.model_name.human)
      redirect_to news_items_path
    else
      flash[:error] = @news.errors.full_messages.join('. ')
      render :edit
    end
  end

  def destroy
    if current_user.company.news_items.find(params[:id]).destroy
      flash[:success] = t('flash.notice.model_deleted', model: NewsItem.model_name.human)
    else
      flash[:error] = t('flash.error.model_deleted', model: NewsItem.model_name.human)
    end
    redirect_to news_items_path
  end

  private

  def news_item_params
    params.require(:news).permit :body, :portal
  end
end
