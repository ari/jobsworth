module CustomersHelper

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
    link_to_function "Add search filter" do |page|
      page.insert_html(:bottom, "customer_search_filters",
                       :partial => "search_filter_prompt")
    end
  end
end
