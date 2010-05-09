class ScmChangesetsController < ApplicationController
  skip_before_filter :authorize, :only=>[:create]
  #Changesets should be created only by api, not by user.
  def create
    @scm_changeset=ScmChangeset.new_from_web_hook(params)
    if @scm_changeset.save
      render :status=> :created
    else
      render :status=> :unprocessable_entity
    end
  end
end
