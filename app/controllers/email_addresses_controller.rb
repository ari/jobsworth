# encoding: UTF-8
class EmailAddressesController < ApplicationController

  def update
    @email_address = EmailAddress.find(params[:id])
    @email_address.link_to_user(params[:email_address][:user_id])
    flash[:success] = _('email attached to user successfully.')
    render :edit
  end

  def edit
    @email_address = EmailAddress.find(params[:id])
  end

end
