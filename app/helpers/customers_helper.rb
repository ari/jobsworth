# encoding: UTF-8
module CustomersHelper

  ###
  # Returns the html to link to a page to create a user
  # for the given customer
  ###
  def create_users_link(customer, options = {})
    url = {
      :controller => "users",
      :action => "new",
      :user => { :customer_id => @customer.id }
    }

    return link_to(t('forms.action.create', model: User.model_name.human), url, options)
  end

end
