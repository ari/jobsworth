# encoding: UTF-8
class ProjectSweeper < ActionController::Caching::Sweeper
    observe Project, ProjectPermission

    def after_save(record)
      expire_fragment( %r{application/projects\.action_suffix=#{record.company_id}.*} )  
    end
    def after_update(record)
      expire_fragment( %r{application/projects\.action_suffix=#{record.company_id}.*} )  
    end
    def after_create(record)
      expire_fragment( %r{application/projects\.action_suffix=#{record.company_id}.*} )  
    end
    def after_destroy(record)
      expire_fragment( %r{application/projects\.action_suffix=#{record.company_id}.*} )  
    end

    
end

