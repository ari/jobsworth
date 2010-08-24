class ScmChangesetsController < ApplicationController
  skip_before_filter :authorize, :only=>[:create]
  #Changesets should be created only by api, not by user.
  def create
    if ScmChangeset.create_from_web_hook(params)
      render :text=>'', :status=> :created
    else
      render :text=>'', :status=> :unprocessable_entity
    end
  end
  def list
    @scm_changesets = ScmChangeset.for_list(params)
    if @scm_changesets.nil?
      render :text=>"" and return
    end
  end
end
