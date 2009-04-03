module CustomAttributesHelper
  def link_to_add_attribute
    link_to_function(_("Add another attribute")) do |page| 
      page.insert_html(:bottom, "attributes", 
                       :partial => "attribute", 
                       :locals => { :attribute => CustomAttribute.new }) 
    end
  end
end
