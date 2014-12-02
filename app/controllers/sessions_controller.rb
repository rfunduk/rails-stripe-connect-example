class SessionsController < ApplicationController

  # Basic login page.
  # app/views/sessions/new.html.haml
  def new
  end

  # Standard basic login feature. Sets a session
  # key of 'user_id' with the authenticated user's
  # ID if they supply the correct credentials.
  def create
    user = User.find_by( email: params[:email].downcase )
    if user && user.authenticate( params[:password] )
      session[:user_id] = user.id
      redirect_to users_path
    else
      flash[:error] = "Invalid email or password :("
      render action: 'new'
    end
  end

  # Logout...
  def destroy
    session.delete :user_id
    redirect_to root_path
  end

end
