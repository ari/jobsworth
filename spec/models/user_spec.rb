require 'spec_helper'

describe User do
  before(:each) do
    @user = User.make(:admin)
  end

  describe 'password' do
    let(:user) { User.make }

    it 'should be encrypted with ssha' do
      expect(user.encrypted_password).to match(/^{SSHA}/)
    end
  end

  describe 'method can?' do
    it "should accept 'see_unwatched' " do
      expect(@user.can?(@user.projects.first, 'see_unwatched')).to be_truthy
    end
  end

  describe 'access level' do
    it 'should belongs to  access level' do
      expect(User.reflect_on_association(:access_level)).not_to be_nil
    end
    it 'should have access level with id 1 by default' do
      user=User.new
      expect(user.access_level_id).to eq(1)
    end
  end

  describe 'destroy' do
    before(:each) do
      @user=User.make
      @user.work_logs.clear
      # Users don't have a topic association
      #@user.topics.clear
      # Users don't have a post association
      #@user.posts.clear
    end

    it 'should destroy user' do
      @user.destroy
      expect(User.find_by(:id => @user.id)).to be_nil
    end

    it 'should not destroy if work logs exist' do
      @user.work_logs << WorkLog.make
      @user.save!
      expect(@user.destroy).to eq(false)
    end

    it 'should not destroy if topics exist' do
      skip "Users don't have a topic association"
      @user.topics << Topic.make
      @user.save!
      expect(@user.destroy).to eq(false)
    end

    it 'should not destroy if posts exist' do
      skip "Users don't have a posts association"
      @user.posts << Post.make
      @user.save!
      expect(@user.destroy).to eq(false)
    end

    it 'should set tasks.creator_id to NULL' do
      t=TaskRecord.make(:creator=>@user, :company=>@user.company)
      expect(t.creator).to eq(@user)
      expect(@user.destroy).not_to eq(false)
      expect(t.reload.creator).to be_nil
    end

    it 'should not touch tasks.creator_id if user not destroyed' do
      t=TaskRecord.make(:creator=>@user, :company=>@user.company)
      expect(t.creator).to eq(@user)
      @user.work_logs << WorkLog.make
      @user.save!
      expect(@user.destroy).to eq(false)
      expect(t.reload.creator).to eq(@user.reload)
    end
  end

  describe '#can_use_billing?' do
    subject{ FactoryGirl.create(:admin) }

    it 'should return true if company allows billing use' do
      subject.company.use_billing = true
      expect(subject.can_use_billing?).to be_truthy
    end

    it "should return false if company doesn't allow billing use" do
      subject.company.use_billing = false
      expect(subject.can_use_billing?).to be_falsey
    end
  end

  describe 'Use resources' do
    subject{ FactoryGirl.create(:admin) }

    it 'should be true if company allow user allow' do
      subject.use_resources = true
      expect(subject.use_resources?).to be_truthy
    end

    it 'should be false if company allow user disallow' do
      expect(subject.use_resources?).to be_falsey
    end

    it 'should be false if company disallow user allows' do
      subject.company.use_resources = false
      expect(subject.use_resources?).to be_falsey
    end

    it 'should be false if company disallow user disallow' do
      subject.company.use_resources = false
      subject.use_resources = false
      expect(subject.use_resources?).to be_falsey
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
#  newsletter                 :integer(4)      default(1)
#  option_avatars             :integer(4)      default(1)
#  autologin                  :string(255)     not null
#  remember_until             :datetime
#  option_floating_chat       :boolean(1)      default(TRUE)
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

