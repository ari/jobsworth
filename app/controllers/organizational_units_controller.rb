# encoding: UTF-8
class OrganizationalUnitsController < ApplicationController
  before_filter :load_customer

  def new
    @org_unit = OrganizationalUnit.new(:customer => @customer)
  end

  def create
    @org_unit = OrganizationalUnit.new(params[:organizational_unit])
    @org_unit.customer = @customer

    respond_to do |format|
      if @org_unit.save
        flash[:success] = 'Organization Unit was successfully created.'
        format.html { send_to_customer_page }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def edit
    @org_unit = @customer.organizational_units.find(params[:id])
  end

  def update
    @org_unit = @customer.organizational_units.find(params[:id])

    respond_to do |format|
      if @org_unit.update_attributes(params[:organizational_unit])
        flash[:success] = 'Organization Unit was successfully updated.'
        @org_unit.update_attribute(:customer_id, @customer.id)
        format.html { send_to_customer_page }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @org_unit = @customer.organizational_units.find(params[:id])
    @org_unit.destroy

    respond_to do |format|
      format.html { send_to_customer_page }
      format.xml  { head :ok }
    end
  end

  private

  def load_customer
    id = params[:customer_id]
    id ||= params[:organizational_unit][:customer_id] if params[:organizational_unit]

    if id
      @customer ||= current_user.company.customers.find(id)
    else
      org_unit = OrganizationalUnit.find(params[:id])
      if current_user.company.customers.include?(org_unit.customer)
        @customer = org_unit.customer
      end
    end
  end

  def send_to_customer_page
    redirect_to(:id => @customer.id, :action => "edit", 
                :controller => "customers", :anchor => "organizational_units")
  end
end
