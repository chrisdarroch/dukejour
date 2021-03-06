class ApplicationController < ActionController::Base
  include Hammock::RestfulActions

  helper :all
  layout 'application'
  protect_from_forgery

  after_filter :log_hit

  private

  def current_user
    @current_user ||= User.find_or_create_with :ip => request.remote_ip
  end
  helper_method :current_user

  def render_juggernaut function, data
    call_via_juggernaut function, data
    render :nothing => true
  end
end
