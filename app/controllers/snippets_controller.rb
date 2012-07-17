class SnippetsController < ApplicationController
  before_filter :authorize_user_is_admin, :only => [:index, :new, :edit, :create, :update, :delete]
  before_filter :authenticate_user!, :only => [:show]

  # GET /snippets
  # GET /snippets.json
  def index
    @snippets = current_user.company.snippets

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @snippets }
    end
  end

  # GET /snippets/1
  # GET /snippets/1.json
  def show
    @snippet = current_user.company.snippets.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @snippet }
    end
  end

  # GET /snippets/new
  # GET /snippets/new.json
  def new
    @snippet = Snippet.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @snippet }
    end
  end

  # GET /snippets/1/edit
  def edit
    @snippet = current_user.company.snippets.find(params[:id])
  end

  # POST /snippets
  # POST /snippets.json
  def create
    @snippet = Snippet.new(params[:snippet])
    @snippet.company = current_user.company
    @snippet.user = current_user

    respond_to do |format|
      if @snippet.save
        format.html { redirect_to @snippet, :flash => {:success => 'Snippet was successfully created.'} }
        format.json { render json: @snippet, status: :created, location: @snippet }
      else
        format.html { render action: "new" }
        format.json { render json: @snippet.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /snippets/1
  # PUT /snippets/1.json
  def update
    @snippet = current_user.company.snippets.find(params[:id])

    respond_to do |format|
      if @snippet.update_attributes(params[:snippet].slice(:name, :body))
        format.html { redirect_to @snippet, :flash => {:success => 'Snippet was successfully updated.'} }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @snippet.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /snippets/1
  # DELETE /snippets/1.json
  def destroy
    @snippet = current_user.company.snippets.find(params[:id])
    @snippet.destroy

    respond_to do |format|
      format.html { redirect_to snippets_url }
      format.json { head :ok }
    end
  end
end
