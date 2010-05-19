class CompaniesController < ApplicationController
  before_filter :check_access
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
private
  def check_access
    unless current_user.admin?
      flash['notice'] = _("Only admins can edit company settings.")
      redirect_from_last
      return false
    end
  end
end
