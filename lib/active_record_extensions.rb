class ActiveRecord::Base
  # Creates a  method  to allow the association to be
  # set using params from a form.
  #
  # In order to restrict access, any class calling this method
  # must have a method named company which will be used to find any
  # new associated objects.
  #
  # The params should be a hash of ids of the object to be added. 
  # Any existing members of the association without an id in params
  # will be removed from the association.
  def self.adds_and_removes_using_params(association)
    method_name = "#{ association.to_s.singularize }_attributes="

    method = <<-EOS
      def #{ method_name }(params)
        add_and_delete_from_attributes(\"#{ association }\", params)
      end
    EOS
    class_eval(method)
  end

  # Called by adds_and_removes_using_params.
  # See that method for an explanation.
  def add_and_delete_from_attributes(association_name, params)
    association_objects = self.send(association_name)
    klass = association_objects.build.class
    updated = []
    
    params.each do |id, ignored_params|
      existing = association_objects.detect { |o| o.id == id.to_i }
      if existing.nil?
        existing = company.send(association_name).find(id)
        association_objects << existing
      end

      updated << existing
    end

    missing = association_objects - updated
    association_objects.delete(missing)
  end
  

end
