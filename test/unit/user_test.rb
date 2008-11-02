require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures :users, :projects, :project_permissions, :companies, :customers

  def setup
    @user = users(:admin)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of User,  @user
  end

  def test_create
    u = User.new
    u.name = "a"
    u.username = "a"
    u.password = "a"
    u.email = "a@a.com"
    u.company = companies(:cit)
    u.save
    
    assert_not_nil u.uuid
    assert_not_nil u.autologin
    
    assert u.uuid.length == 32
    assert u.autologin.length == 32
    
    assert u.widgets.size == 5
  end

  def test_validate_name
    u = User.new
    u.username = "a"
    u.password = "a"
    u.email = "a@a.com"
    u.company = companies(:cit)

    assert !u.save
    assert_equal 1, u.errors.size
    assert_equal "can't be blank", u.errors['name'] 
    
  end
  
  def test_validate_username
    u = User.new
    u.name = "a"
    u.password = "a"
    u.email = "a@a.com"
    u.company = companies(:cit)

    assert !u.save
    assert_equal 1, u.errors.size
    assert_equal "can't be blank", u.errors['username'] 

    u.username = 'test'
    assert !u.save
    assert_equal 1, u.errors.size
    assert_equal "has already been taken", u.errors['username'] 
    
  end

  def test_validate_password
    u = User.new
    u.name = "a"
    u.username = "a"
    u.email = "a@a.com"
    u.company = companies(:cit)

    assert !u.save
    assert_equal 1, u.errors.size
    assert_equal "can't be blank", u.errors['password'] 
    
  end

  def test_validate_email
    u = User.new
    u.name = "a"
    u.username = "a"
    u.password = "a"
    u.company = companies(:cit)

    assert !u.save
    assert_equal 1, u.errors.size
    assert_equal "can't be blank", u.errors['email']
  end

  def test_validate_company_id
    u = User.new
    u.name = "a"
    u.username = "a"
    u.password = "a"
    u.email = "a@a.com"

    assert !u.save
    assert_equal 1, u.errors.size
    assert_equal "can't be blank", u.errors['company'] 
  end


  def test_path
    assert_equal File.join("#{RAILS_ROOT}", 'store', 'avatars', "#{@user.company_id}"), @user.path
  end
  
  def test_avatar_path
    assert_equal File.join("#{RAILS_ROOT}", 'store', 'avatars', "#{@user.company_id}", "#{@user.id}"), @user.avatar_path
  end
  
  def test_avatar_large_path
    assert_equal File.join("#{RAILS_ROOT}", 'store', 'avatars', "#{@user.company_id}", "#{@user.id}_large"), @user.avatar_large_path
  end
  
  def test_generate_uuid
    user = User.new
    user.generate_uuid

    assert_not_nil user.uuid
     assert_not_nil user.autologin
    
    assert user.uuid.length == 32
    assert user.autologin.length == 32
  end

  def test_avatar_url
    if @user.avatar?
      assert_equal "/users/avatar/1?large=1", @user.avatar_url
      assert_equal "/users/avatar/1", @user.avatar_url(25)
    else 
      assert_equal "http://www.gravatar.com/avatar.php?gravatar_id=7fe6da9c206af10497cdc35d63cf87a3&rating=PG&size=32", @user.avatar_url
      assert_equal "http://www.gravatar.com/avatar.php?gravatar_id=7fe6da9c206af10497cdc35d63cf87a3&rating=PG&size=25", @user.avatar_url(25)
    end
  end

  def test_display_name
    assert_equal "Erlend Simonsen", @user.name
  end

  def test_login
    assert_equal @user, @user.login('cit')
    assert_nil   @user.login
    assert_nil   @user.login('www')
    assert_nil   User.new.login('cit')
    assert_nil   users(:fudge).login('cit')
  end
  
  def test_can?
    project = projects(:test_project)
    normal = users(:tester)
    limited = users(:tester_limited)
    other = users(:fudge)
    
    %w(comment work close report create edit reassign prioritize milestone grant all).each do |perm|
       assert normal.can?(project, perm)
       assert !other.can?(project, perm)
      if %w(comment work).include? perm
        assert limited.can?(project, perm)
      else
        assert !limited.can?(project, perm)
      end
    end
  end
  
  def test_can_all?
    projects = [projects(:test_project), projects(:completed_project)]
    normal = users(:tester)
    limited = users(:tester_limited)
    other = users(:fudge)

    %w( comment work close report create edit reassign prioritize milestone grant all).each do |perm|
      assert normal.can_all?(projects, perm)
      assert !other.can_all?(projects, perm)
      assert !limited.can_all?(projects, perm)
    end 
  end
  
  def test_admin?
    assert @user.admin?
    assert !users(:fudge).admin?
    assert !User.new.admin?
  end

  def test_currently_online
    @user2 = users(:tester)
    assert_equal [@user,@user2], @user.currently_online
    assert_equal [], users(:fudge).currently_online
  end

  def test_moderator_of?
    # TODO
  end
  
  def test_online?
    @user.last_ping_at = Time.now.utc
    
    assert @user.online?
    assert !users(:fudge).online?
    
  end

  def test_online_status_name
    @user.last_ping_at = Time.now.utc 
    @user.last_seen_at = Time.now.utc 
    assert_match /status-online/, @user.online_status_name

    @user.last_ping_at = Time.now.utc - 4.minutes
    @user.last_seen_at = Time.now.utc 
    assert_match /status-offline/, @user.online_status_name
    
    @user.last_ping_at = Time.now.utc - 1.minutes
    @user.last_seen_at = Time.now.utc - 10.minutes
    assert_match /status-idle/, @user.online_status_name
  end
  
end
