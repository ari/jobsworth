module Devise::AdminContextMacro

  def signed_in_admin_context(&blk)
    context "As a signed in admin," do
      setup do
        @user = User.make(:admin)
        sign_in @user
        @user.company.create_default_statuses
      end
      merge_block(&blk)
    end
  end

end
