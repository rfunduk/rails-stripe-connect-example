class ApplicationController < ActionController::Base
  include ApplicationHelper

  protect_from_forgery with: :exception

  protected

  # A simple before_action to redirect a non-logged-in
  # user to the login page
  def require_user
    if session[:user_id].blank?
      redirect_to new_sessions_path
      return
    end
  end
end
