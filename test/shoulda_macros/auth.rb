class ActiveSupport::TestCase < Test::Unit::TestCase
  class << self
    def signed_in_admin_context(&blk)
      context "As a signed in admin," do
        setup do
          @user = users(:admin)
          sign_in @user
          @user.company.create_default_statuses
        end

        merge_block(&blk)
      end
    end

  end
end
