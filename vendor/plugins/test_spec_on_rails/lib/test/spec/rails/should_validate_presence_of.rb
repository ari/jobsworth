module Test::Spec::Rails::ShouldValidatePresenceOf
  def it_should_validate_presence_of(*one_or_more_fields)
    model_name = self.model_class_under_test
    options = one_or_more_fields.last.is_a?(Hash) ? one_or_more_fields.pop : {}
  
    one_or_more_fields.each do |field|
      it "should validate presence of #{field.to_s.humanize.downcase}" do
        validations = model_name.reflect_on_all_validations
        validations = validations.select { |e| e.macro == :validates_presence_of }
        validations = validations.inject({}) { |h,v| h[v.name] = v; h }
      
        validation = validations[field]
        assert_not_nil validation, "Expected validates_presence_of to be called on :#{field}, but it wasn't"
        options.each_pair do |k,v|
          assert_equal v, validation.options[k],
            "Expected validates_presence_of to set :#{k} => :#{v} as an option, but it didn't"
        end
      end
    end
  end
  
  def model_class_under_test
    name.constantize
  end
end

Test::Unit::TestCase.send(:extend, Test::Spec::Rails::ShouldValidatePresenceOf)