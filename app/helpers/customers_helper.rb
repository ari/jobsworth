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
  # Returns the html to show pagination links for the given
  # customers array.
  ###
  def pagination_links(customers)
    will_paginate(@customers, { 
                    :per_page => 100,
                    :next_label => _('Next') + ' &raquo;', 
                    :prev_label => '&laquo; ' + _('Previous')
                  })
  end
end
