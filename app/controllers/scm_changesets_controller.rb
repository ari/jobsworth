# encoding: UTF-8
class ScmChangesetsController < ApplicationController

  # this controller is called without authentication
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token

  #Changesets should be created only by api, not by user.
  def create
    if ScmChangeset.create_from_web_hook(params)
      render :text => '', :status => :created
    else
      render :text => '', :status => :unprocessable_entity
    end
  end

  def list
    @scm_changesets = ScmChangeset.for_list(params)
    if @scm_changesets.nil?
      render :text => '' and return
    end
  end

end
