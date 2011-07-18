# encoding: UTF-8
class CompaniesController < ApplicationController
  before_filter :authorize_user_is_admin

  def edit
    @company = current_user.company
  end

  def update
    @company = current_user.company

    @internal = @company.internal_customer

    if @internal.nil?
      flash['notice'] = 'Unable to find internal customer.'
      render :action => 'edit'
      return
    end

    if @company.update_attributes(params[:company])
      @internal.name = @company.name
      @internal.save

      flash['notice'] = _('Company settings updated')
      redirect_from_last
    else
      render :action => 'edit'
    end
  end
end
