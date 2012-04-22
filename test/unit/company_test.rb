require "test_helper"

class CompanyTest < ActiveRecord::TestCase
  fixtures :companies, :customers

  should have_many(:preferences)
  should have_many(:properties)
  should have_many(:property_values).through(:properties)
  should have_many(:task_filters).dependent(:destroy)
  should have_many(:statuses).dependent(:destroy)
  should have_many(:wiki_pages).dependent(:destroy)
  should have_many(:triggers).dependent(:destroy)

  def setup
    @company = companies(:cit)
  end
  subject { @company }

  def test_truth
    assert_kind_of Company,  @company
  end

  def test_internal_customer
    assert_equal "Internal", @company.internal_customer.name
  end

  def test_subdomain_uniqueness
    company = Company.new
    company.name = "Test"
    company.subdomain = 'cit'

    assert !company.valid?
    assert !company.errors[:subdomain].empty?

    company.subdomain = 'unique-name'
    assert company.valid?
    assert company.errors[:subdomain].empty?
  end

  def test_company_should_create_default_properties_on_create
    c = Company.new(:name => "test", :subdomain => "test")
    assert c.save

    type = c.properties.find_by_name("Type")
    assert_not_nil type
    assert_equal 4, type.property_values.length

    severity = c.properties.find_by_name("Severity")
    assert_not_nil severity
    assert_equal 6, severity.property_values.length

    priority = c.properties.find_by_name("Priority")
    assert_not_nil priority
    assert_equal 6, priority.property_values.length
  end

  def test_property_helper_methods
    @company.create_default_properties

    ensure_property_method_works_with_translation(:type_property)
  end

  test "preference_attributes should create preferences" do
    assert @company.preferences.empty?
    @company.preference_attributes = { "p1" => "v1", "p2" => "v2" }
    assert_equal 2, @company.preferences.length
  end

  test "preference_attributes should update existing preferences" do
    assert @company.preferences.empty?
    assert @company.preferences.build(:key => "p1", :value => "v1").save!
    assert_equal 1, @company.preferences.length

    @company.preference_attributes = { :p1 => "v2" }
    assert_equal 1, @company.preferences.length
    assert_equal "v2", @company.preferences.first.value
  end

  test "preference should return the attribute" do
    assert @company.preferences.build(:key => "p1", :value => "v1").save!
    assert_equal "v1", @company.preference("p1")
    assert_nil @company.preference("p2")
  end

  context "a company with default properties" do
    setup do
      @company.create_default_properties
    end

    should "have priority" do
      assert_not_nil @company.properties.detect{ |p| p.name == "Priority" }
    end

    should "have property values in the top 33% as critical" do
      values = @company.critical_values.map { |v| v.value }
      assert_equal [ "Blocker", "Critical", "Critical", "Urgent"], values.sort
    end

    should "have property values in the middle 34% as normal" do
      values = @company.normal_values.map { |v| v.value }
      assert_equal [ "High", "Major", "Normal", "Normal" ], values.sort
    end

    should "have property values in the bottom 33% as low" do
      values = @company.low_values.map { |v| v.value }
      assert_equal [ "Low", "Lowest", "Minor", "Trivial" ], values.sort
    end
  end

  private

  def ensure_property_method_works_with_translation(method)
    prop = @company.send(method)
    assert_not_nil prop

    Localization.lang("eu_ES")
    prop.name = _(prop.name)
    prop.save

    prop_after_translation = @company.send(method)
    assert_equal prop, prop_after_translation

    Localization.lang("en_US")
  end
end










# == Schema Information
#
# Table name: companies
#
#  id                         :integer(4)      not null, primary key
#  name                       :string(200)     default(""), not null
#  contact_email              :string(200)
#  contact_name               :string(200)
#  created_at                 :datetime
#  updated_at                 :datetime
#  subdomain                  :string(255)     default(""), not null
#  show_wiki                  :boolean(1)      default(TRUE)
#  suppressed_email_addresses :string(255)
#  logo_file_name             :string(255)
#  logo_content_type          :string(255)
#  logo_file_size             :integer(4)
#  logo_updated_at            :datetime
#
# Indexes
#
#  index_companies_on_subdomain  (subdomain) UNIQUE
#

