require "test_helper"

class ProjectFileTest < ActiveRecord::TestCase
  # Replace this with your real tests.
  should "be able to detect tell image from non-image" do
    file = ProjectFile.make(:file_file_name => "a.png")
    assert file.image?

    file = ProjectFile.make(:file_file_name => "a.PNG")
    assert file.image?

    file = ProjectFile.make(:file_file_name => "a.jpg")
    assert file.image?

    file = ProjectFile.make(:file_file_name => "a.JPG")
    assert file.image?

    file = ProjectFile.make(:file_file_name => "a.gif")
    assert file.image?

    file = ProjectFile.make(:file_file_name => "a.GIF")
    assert file.image?

    file = ProjectFile.make(:file_file_name => "a.log")
    assert !file.image?
  end

  context "files" do
    should "be able to png files" do
      photo = ProjectFile.make :file => Rails.root.join("app/assets/images/rails.png").open
      assert photo.image?
      assert photo.thumbnail?
      assert File.exists?(photo.file_path)
    end

    should "be able to gif files" do
      photo = ProjectFile.make :file => Rails.root.join("app/assets/images/ajax-bar-loader.gif").open
      assert photo.image?
      assert photo.thumbnail?
      assert File.exists?(photo.file_path)
    end
  end
end
