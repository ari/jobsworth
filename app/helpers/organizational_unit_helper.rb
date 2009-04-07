module OrganizationalUnitHelper

  ###
  # Returns the html for a link that adds in a new 
  # organizational unit
  ###
  def add_org_unit_link
    link_to_function(_("Add Organizational Unit")) do |page|
      @org_unit = OrganizationalUnit.new(:customer => @customer)
      page.insert_html(:bottom, "org_units",
                       :partial => "org_unit")
    end
  end

end
