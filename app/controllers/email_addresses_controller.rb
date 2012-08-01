# encoding: UTF-8
class EmailAddressesController < ApplicationController
  layout 'basic'

  def index
    @email_addresses = current_user.company.email_addresses.where("user_id IS NULL").order("email ASC").paginate(:page => params[:page], :per_page => 10)
  end

  def update
    @email_address = current_user.company.email_addresses.find(params[:id])
    @email_address.link_to_user(params[:email_address][:user_id])
    flash[:success] = _('email attached to user successfully.')
    render :edit
  end

  def edit
    @email_address = current_user.company.email_addresses.find(params[:id])
  end

end
