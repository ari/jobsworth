require "test_helper"

class ProjectTest < ActiveRecord::TestCase
  fixtures :projects, :companies, :users, :customers

  def setup
    @project = projects(:test_project)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Project,  @project
  end

  def test_validate_name
    p = Project.new
    p.users << users(:admin)
    p.company = companies(:cit)
    p.customer = customers(:internal_customer)

    assert !p.save
    assert_equal 1, p.errors.size
    assert_equal "can't be blank", p.errors['name'].first

  end

  def test_full_name
    assert_equal "Internal / Test Project", @project.full_name
  end

  def test_to_css_name
    assert_equal "test-project internal", @project.to_css_name
  end

end







# == Schema Information
#
# Table name: projects
#
#  id               :integer(4)      not null, primary key
#  name             :string(200)     default(""), not null
#  company_id       :integer(4)      default(0), not null
#  customer_id      :integer(4)      default(0), not null
#  created_at       :datetime
#  updated_at       :datetime
#  completed_at     :datetime
#  critical_count   :integer(4)      default(0)
#  normal_count     :integer(4)      default(0)
#  low_count        :integer(4)      default(0)
#  description      :text
#  open_tasks       :integer(4)
#  total_tasks      :integer(4)
#  total_milestones :integer(4)
#  open_milestones  :integer(4)
#  default_estimate :decimal(5, 2)   default(1.0)
#  neverBill        :boolean(1)
#
# Indexes
#
#  projects_company_id_index   (company_id)
#  projects_customer_id_index  (customer_id)
#

