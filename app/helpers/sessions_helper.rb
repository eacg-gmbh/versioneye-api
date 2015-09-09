module SessionsHelper

  def current_user=(user)
    @current_user = user
  end

  def current_user
    @current_user ||= user_from_remember_token
  end

  def current_user?(user)
    return false if user.nil?
    return nil   if current_user.nil?
    user.username.eql? current_user.username
  end

  def signed_in?
    !current_user.nil?
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    false
  end

  def authenticate
    return true if signed_in?
    deny_access
    false
  end

  def deny_access
    store_location
    redirect_to signin_path, :notice => 'Please sign in to access this page.'
  end

  def redirect_back_or(default)
    redirect_to(session[:return_to] || default, :status => 302)
    clear_return_to
  end

  private

    def user_from_remember_token
      User.authenticate_with_salt(*remember_token)
    rescue => e
      Rails.logger.info e.message
      Rails.logger.error e.backtrace.join("\n")
      nil
    end

    def remember_token
      cookies.signed[:remember_token] || [nil, nil]
    end

    def store_location
      session[:return_to] = request.fullpath
    end

    def clear_return_to
      session[:return_to] = nil
    end

end
