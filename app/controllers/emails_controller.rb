class EmailsController < ApplicationController
  skip_before_filter :authenticate_user!, :only => [:create]

  def create
    if params[:secret]!= Setting.receiving_emails.secret
      return render json: {success: false, message: "The secret key is incorrect."}
    end

    Mailman.receive(params[:email])

    render json: {success: true}
  end
end
