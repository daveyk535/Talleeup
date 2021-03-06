
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  before_action :configure_devise_permitted_parameters, if: :devise_controller?
  # before_action :authenticate_user!
  protected

  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) ||
        if resource_or_scope.is_a?(Admin)
          admin_dashboard_path
        else
          '/home/login'
        end
  end

  def configure_devise_permitted_parameters
    registration_params = [:fullname, :email, :password, :password_confirmation]

    if params[:action] == 'update'
      devise_parameter_sanitizer.for(:account_update) {
          |u| u.permit(registration_params << :current_password)
      }
    elsif params[:action] == 'create'
      devise_parameter_sanitizer.for(:sign_up) {
          |u| u.permit(registration_params)
      }
    end
  end

  protect_from_forgery with: :exception
  include Mobvious::Rails::Controller
  helper_method :device_type
  def device_type
    request.env['mobvious.device_type']
  end



end
