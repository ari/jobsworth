module ClientsHelper

  ###
  # Returns the html to link to a page to create a user
  # for the given customer
  ###
  def create_users_link(customer)
    url = {
      :controller => "users", 
      :action => "new", 
      :user => { :customer_id => @customer.id }
    }

    return link_to(_("Create User"), url)
  end

  ###
  # Returns the html for a link that adds in a new 
  # search filter field.
  ###
  def add_search_filter_link
    link_to_function _("Add search filter") do |page|
      page.insert_html(:bottom, "customer_search_filters",
                       :partial => "search_filter_prompt")
    end
  end

  ###
  # Returns html to display any users in the given list
  # that belong to the given customer.
  ###
  def users_for_customer(users, customer)
    return if users.nil?

    res = []
    users.each do |u|
      next if u.customer != customer
      res << link_to(h(u.name), 
                     :controller => "users", :action => "edit", :id => u)
    end

    res = res.map { |str| "<li style=\"margin-left: 24px\">#{ str }</li>" }
    return res.join("\n")
  end
end
