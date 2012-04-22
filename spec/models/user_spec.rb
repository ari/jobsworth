require 'spec_helper'

describe User do
  fixtures :users, :projects, :project_permissions

  before(:each) do
    @user = users(:admin)
  end

  describe "#working_hours" do
    let(:user) { User.make }

    it "should have a working_hours attribute" do
      user.should respond_to :working_hours
    end

    it "should default to 8 hours for the week days and 0 for the weekend" do
      user.working_hours.should match "8.0|8.0|8.0|8.0|8.0|0.0|0.0"
    end
  end

  describe "password" do
    let(:user) { User.make }

    it "should be encrypted with ssha" do
      user.encrypted_password.should =~ /^{SSHA}/
    end
  end

  describe "validations" do
    let(:user) { User.make }

    it "should require some working hours" do
      user.working_hours = nil
      user.should_not be_valid
    end

    it "should require the working hours to be not negative numbers" do
      user.working_hours = "-1.0|0.0|0.0|0.0|0.0|0.0|0.0"
      user.should_not be_valid
    end

    it "should requre the working hours to be numbers" do
      user.working_hours = "lol"
      user.should_not be_valid
    end
  end

  describe "#get_working_hours_for" do
    let(:user) { User.make }

    context "Given a valid date" do
      let(:epoch) { Time.at(0).utc }

      before(:each) do
        user.working_hours = "4.0|4.0|4.0|4.0|8.0|0.0|0.0"
      end

      it "should return the working hours for that day of week" do
        # Since the epoch occured a friday 
        # get_working_hours_for should return 8.0
        user.get_working_hours_for(epoch).should == 8.0
      end
    end
  end

  describe "method can?" do
    it "should accept 'see_unwatched' " do
      @user.can?(@user.projects.first, 'see_unwatched').should be_true
    end
  end

  describe "access level" do
    it "should belongs to  access level" do
      User.reflect_on_association(:access_level).should_not be_nil
    end
    it "should have access level with id 1 by default" do
      user=User.new
      user.access_level_id.should == 1
    end
  end

  describe "destroy" do
    before(:each) do
      @user=User.make
      @user.work_logs.clear
      # Users don't have a topic association
      #@user.topics.clear
      # Users don't have a post association
      #@user.posts.clear
    end

    it "should destroy user" do
      @user.destroy
      User.find_by_id(@user.id).should be_nil
    end

    it "should not destroy if work logs exist" do
      @user.work_logs << WorkLog.make
      @user.save!
      @user.destroy.should == false
    end

    it "should not destroy if topics exist" do
      pending "Users don't have a topic association"
      @user.topics << Topic.make
      @user.save!
      @user.destroy.should == false
    end

    it "should not destroy if posts exist" do
      pending "Users don't have a posts association"
      @user.posts << Post.make
      @user.save!
      @user.destroy.should == false
    end

    it "should set tasks.creator_id to NULL" do
      t=Task.make(:creator=>@user, :company=>@user.company)
      t.creator.should == @user
      @user.destroy.should_not == false
      t.reload.creator.should be_nil
    end

    it "should not touch tasks.creator_id if user not destroyed" do
      t=Task.make(:creator=>@user, :company=>@user.company)
      t.creator.should == @user
      @user.work_logs << WorkLog.make
      @user.save!
      @user.destroy.should == false
      t.reload.creator.should == @user.reload
    end
  end
end






# == Schema Information
#
# Table name: users
#
#  id                         :integer(4)      not null, primary key
#  name                       :string(200)     default(""), not null
#  username                   :string(200)     default(""), not null
#  company_id                 :integer(4)      default(0), not null
#  created_at                 :datetime
#  updated_at                 :datetime
#  admin                      :integer(4)      default(0)
#  time_zone                  :string(255)
#  option_tracktime           :integer(4)
#  seen_news_id               :integer(4)      default(0)
#  last_project_id            :integer(4)
#  last_seen_at               :datetime
#  last_ping_at               :datetime
#  last_milestone_id          :integer(4)
#  last_filter                :integer(4)
#  date_format                :string(255)     default("%d/%m/%Y"), not null
#  time_format                :string(255)     default("%H:%M"), not null
#  receive_notifications      :integer(4)      default(1)
#  uuid                       :string(255)     not null
#  seen_welcome               :integer(4)      default(0)
#  locale                     :string(255)     default("en_US")
#  duration_format            :integer(4)      default(0)
#  workday_duration           :integer(4)      default(480)
#  newsletter                 :integer(4)      default(1)
#  option_avatars             :integer(4)      default(1)
#  autologin                  :string(255)     not null
#  remember_until             :datetime
#  option_floating_chat       :boolean(1)      default(TRUE)
#  days_per_week              :integer(4)      default(5)
#  enable_sounds              :boolean(1)      default(TRUE)
#  create_projects            :boolean(1)      default(TRUE)
#  show_type_icons            :boolean(1)      default(TRUE)
#  receive_own_notifications  :boolean(1)      default(TRUE)
#  use_resources              :boolean(1)
#  customer_id                :integer(4)
#  active                     :boolean(1)      default(TRUE)
#  read_clients               :boolean(1)      default(FALSE)
#  create_clients             :boolean(1)      default(FALSE)
#  edit_clients               :boolean(1)      default(FALSE)
#  can_approve_work_logs      :boolean(1)
#  auto_add_to_customer_tasks :boolean(1)
#  access_level_id            :integer(4)      default(1)
#  avatar_file_name           :string(255)
#  avatar_content_type        :string(255)
#  avatar_file_size           :integer(4)
#  avatar_updated_at          :datetime
#  use_triggers               :boolean(1)      default(FALSE)
#  encrypted_password         :string(128)     default(""), not null
#  password_salt              :string(255)     default(""), not null
#  reset_password_token       :string(255)
#  remember_token             :string(255)
#  remember_created_at        :datetime
#  sign_in_count              :integer(4)      default(0)
#  current_sign_in_at         :datetime
#  last_sign_in_at            :datetime
#  current_sign_in_ip         :string(255)
#  last_sign_in_ip            :string(255)
#  working_hours              :string(255)     default("8.0|8.0|8.0|8.0|8.0|0.0|0.0"), not null
#  reset_password_sent_at     :datetime
#
# Indexes
#
#  index_users_on_username_and_company_id  (username,company_id) UNIQUE
#  index_users_on_reset_password_token     (reset_password_token) UNIQUE
#  index_users_on_autologin                (autologin)
#  users_company_id_index                  (company_id)
#  index_users_on_customer_id              (customer_id)
#  index_users_on_last_seen_at             (last_seen_at)
#  users_uuid_index                        (uuid)
#

