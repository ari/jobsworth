#This model is to task templates
#use the same table as Task  model.
class Template < Task
  default_scope :condition=>{ :type=>'Template'}

end
