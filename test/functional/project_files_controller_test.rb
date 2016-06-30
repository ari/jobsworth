require 'test_helper'

class ProjectFilesControllerTest < ActionController::TestCase

  def setup
    @user = User.make(:admin)
    sign_in @user
    @request.session[:user_id] = @user.id
    @user.company.create_default_statuses

    project_with_some_tasks(@user)

    @task = @user.tasks.first
    @task.users << @task.company.users
    @task.save!
  end

  teardown do
    @task.attachments.destroy_all
  end

  should "delete the file on disk if other tasks aren't linked to the same file" do
    @task.attachments.make(:company => @user.company,
                           :customer => @task.project.customer,
                           :project => @task.project,
                           :user_id => @user.id,
                           :file => Rails.root.join('test', 'fixtures', 'files', 'rails.png').open,
                           :uri => '450fc241fab7867e96536903244087f4')

    assert_equal true, File.exists?("#{Rails.root}/store/#{@user.company.id}/450fc241fab7867e96536903244087f4_original.png")
    assert_equal true, File.exists?("#{Rails.root}/store/#{@user.company.id}/450fc241fab7867e96536903244087f4_thumbnail.png")

    assert_difference('ProjectFile.count', -1) do
      delete :destroy_file, :id => @task.attachments.first.id
    end
    assert_equal false, File.exists?("#{Rails.root}/store/#{@user.company.id}/450fc241fab7867e96536903244087f4_original.png")
    assert_equal false, File.exists?("#{Rails.root}/store/#{@user.company.id}/450fc241fab7867e96536903244087f4_original.png")
  end

  should 'not delete the file on disk if other tasks are linked to the same file' do
    @task.attachments.make(:company => @user.company,
                           :customer => @task.project.customer,
                           :project => @task.project,
                           :user_id => @user.id,
                           :file => Rails.root.join('test', 'fixtures', 'files', 'suri cruise.jpg').open,
                           :uri => '8e732963114deed0079975414a0811b3')

    @second_task = @user.tasks.last
    @second_task.users << @second_task.company.users
    @second_task.save!
    @second_task.attachments.make(:company => @user.company,
                                  :customer => @second_task.project.customer,
                                  :project => @second_task.project,
                                  :user_id => @user.id,
                                  :file => Rails.root.join('test', 'fixtures', 'files', 'suri cruise.jpg').open,
                                  :uri => '8e732963114deed0079975414a0811b3')

    assert_equal true, File.exists?("#{Rails.root}/store/#{@user.company.id}/8e732963114deed0079975414a0811b3_original.jpg")
    assert_equal true, File.exists?("#{Rails.root}/store/#{@user.company.id}/8e732963114deed0079975414a0811b3_thumbnail.jpg")

    assert_difference('ProjectFile.count', -1) do
      delete :destroy_file, :id => @second_task.attachments.first.id
    end
    assert_equal true, File.exists?("#{Rails.root}/store/#{@user.company.id}/8e732963114deed0079975414a0811b3_original.jpg")
    assert_equal true, File.exists?("#{Rails.root}/store/#{@user.company.id}/8e732963114deed0079975414a0811b3_thumbnail.jpg")
  end

end
