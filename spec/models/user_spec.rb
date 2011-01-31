require 'spec_helper'

describe User do
  fixtures :users, :projects, :project_permissions
  before(:each) do
    @user=users(:admin)
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
#  describe "project_ids_for_sql" do
#    before(:each) do
#      @user=User.make
#    end
#    it "should return project ids joined by ',' if user have prjects" do
#      3.times{ @user.projects<< Project.make }
#      @user.project_ids_for_sql.should == @user.project_ids.join(',')
#    end
#    it "should return '0' if user not have any project" do
#      @user.projects.clear
#      @user.project_ids_for_sql.should == "0"
#    end
#  end

  describe "destroy" do
    before(:each) do
      @user=User.make
      @user.work_logs.clear
      @user.topics.clear
      @user.posts.clear
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
      @user.topics << Topic.make
      @user.save!
      @user.destroy.should == false
    end

    it "should not destroy if posts exist" do
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
#  password                   :string(200)     default(""), not null
#  company_id                 :integer(4)      default(0), not null
#  created_at                 :datetime
#  updated_at                 :datetime
#  last_login_at              :datetime
#  admin                      :integer(4)      default(0)
#  time_zone                  :string(255)
#  option_tracktime           :integer(4)
#  option_externalclients     :integer(4)
#  option_tooltips            :integer(4)
#  seen_news_id               :integer(4)      default(0)
#  last_project_id            :integer(4)
#  last_seen_at               :datetime
#  last_ping_at               :datetime
#  last_milestone_id          :integer(4)
#  last_filter                :integer(4)
#  date_format                :string(255)     not null
#  time_format                :string(255)     not null
#  send_notifications         :integer(4)      default(1)
#  receive_notifications      :integer(4)      default(1)
#  uuid                       :string(255)     not null
#  seen_welcome               :integer(4)      default(0)
#  locale                     :string(255)     default("en_US")
#  duration_format            :integer(4)      default(0)
#  workday_duration           :integer(4)      default(480)
#  posts_count                :integer(4)      default(0)
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
#

