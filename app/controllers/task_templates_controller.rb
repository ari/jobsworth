# encoding: UTF-8
class TaskTemplatesController < TasksController
  def index
    @task_templates = current_templates
    render :layout => "admin"
  end

  def update
    @task = current_templates.find_by_id(params[:id])
    if @task.nil?
      flash[:error] = t('flash.error.not_exists_or_no_permission', model: Template.model_name.human)
      redirect_from_last and return
    end

    @task.send(:do_update, params, current_user)

    flash[:success] ||= link_to_task(@task) + " - #{t('flash.notice.model_updated', model: Template.model_name.human)}"
    redirect_to :action=> "edit", :id => @task.task_num
  end

  def destroy
    @task_template = current_templates.detect { |template| template.id == params[:id].to_i }
    @task_template.destroy
    flash[:success] = t('flash.notice.model_deleted', model: Template.model_name.human)
    redirect_to task_templates_path
  end

  def reorder
    params[:templates].values.each do |template|
      t=AbstractTask.find(template[:id])
      t.position_task_template=template[:position]
      t.save!
    end
    render :nothing=>true
  end

protected
####  This methods inherited from TasksController.
####  They modifies behavior of TasksController actions: new, create, edit, update etc.
####  Please see design pattern Template Method.
  def create_entity
    Template.new(:company => current_user.company)
  end

end
