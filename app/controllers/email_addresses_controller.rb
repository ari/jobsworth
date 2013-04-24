# encoding: UTF-8
class EmailAddressesController < ApplicationController
  layout 'admin'

  def index
    @email_addresses = current_user.company.email_addresses.where("user_id IS NULL").order("email ASC").paginate(:page => params[:page], :per_page => 50)
  end

  def create
    # try link orphaned email address first
    @email_address = current_user.company.email_addresses.where(:email => params[:email_address][:email]).where('user_id IS NULL').first
    @email_address ||= EmailAddress.new(params[:email_address])

    # newly added email address can't be default
    @email_address.default = false
    @email_address.company_id = current_user.company_id

    if @email_address.user != current_user and !current_user.admin?
      return render json: {success: false, message: t('flash.alert.unauthorized_operation')}
    end

    # link to orhpaned email address
    if !@email_address.new_record?
      @email_address.link_to_user(params[:email_address][:user_id])
      html = render_to_string :partial => 'email_addresses/email_address', :locals => {:email_address => @email_address}
      return render :json => {:success => true, :html => html}
    end

    if @email_address.save
      html = render_to_string :partial => 'email_addresses/email_address', :locals => {:email_address => @email_address}
      return render :json => {:success => true, :html => html}
    else
      return render :json => {:success => false, :message => @email_address.errors.full_messages.join(', ') }
    end
  end

  def update
    @email_address = current_user.company.email_addresses.find(params[:id])
    @email_address.link_to_user(params[:email_address][:user_id])
    flash[:success] = t('flash.notice.model_attached_to_other',
                        model: EmailAddress.model_name.human,
                        other: User.model_name.human)
    render :edit
  end

  def edit
    @email_address = current_user.company.email_addresses.find(params[:id])
  end

  def destroy
    @email_address = current_user.company.email_addresses.find(params[:id])

    if @email_address.user != current_user and !current_user.admin?
      return render json: {success: false, message: t('flash.alert.unauthorized_operation')}
    end

    if @email_address.default?
      render :json => {success: false, message: t('flash.error.cant_delete_default_model', model: EmailAddress.model_name.human)}
    else
      @email_address.destroy
      render :json => {success: true}
    end
  end

  def default
    @email_address = current_user.company.email_addresses.find(params[:id])

    if @email_address.user != current_user and !current_user.admin?
      return render :json => {:success => false, :message => t('flash.alert.unauthorized_operation')}
    end

    @email_address.user.email_addresses.update_all(:default => false)
    @email_address.update_column(:default, true)

    render :json => {:success => true}
  end
end
