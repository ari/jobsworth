require File.dirname(__FILE__) + '/../../../test_helper'

describe "TestStatus" do
  it "should call assert_response" do
    status = Test::Spec::Rails::TestStatus.new(stub_everything)
    status.expects(:assert_response).with(:success, nil)
    status.should_equal :success
  end
  
  it "should call assert_response with message" do
    status = Test::Spec::Rails::TestStatus.new(stub_everything)
    status.expects(:assert_response).with(:success, "Response should be successful")
    status.should_equal :success, "Response should be successful"
  end
  
  it "should return response code" do
    status = Test::Spec::Rails::TestStatus.new(stub_everything)
    status.class.class_eval { attr_accessor :response }
    status.response.expects(:response_code).returns("200")
    status.to_s.should == "200"
  end
end