class ScmChangesetsController < ApplicationController
  skip_before_filter :authorize, :only=>[:create]
  #Changesets should be created only by api, not by user.
  def create
    if ScmChangeset.create_from_web_hook(params)
      render :status=> :created
    else
      render :status=> :unprocessable_entity
    end
  end
end
