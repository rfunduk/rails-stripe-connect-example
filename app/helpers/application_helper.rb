module ApplicationHelper

  # Lookup logged in user from session, if applicable.
  def current_user
    @_current_user ||= User.find_by_id( session[:user_id] )
  end

  # Simply checks if the @user instance variable
  # is the current user. Used to check if we're
  # looking our own profile page, basically.
  # See app/views/users/show.html.haml
  def is_myself?
    @user == current_user
  end
end
