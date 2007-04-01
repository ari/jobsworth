class ShoutSweeper < ActionController::Caching::Sweeper
    observe Shout

    def after_save(record)
      expire_fragment( %r{application/chat\.action_suffix=#{record.company_id}.*} )  
    end
end

