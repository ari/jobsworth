class CompaniesController < ApplicationController

  def edit
    unless current_user.admin?
      flash['notice'] = _("Only admins can edit company settings.")
      redirect_from_last
      return
    end

    @company = current_user.company
  end

  def update
    @company = current_user.company
    if @company.update_attributes(params[:company])
      flash['notice'] = _('Company settings updated')
      redirect_from_last
    else
      render :action => 'edit'
    end 
  end
end
