# frozen_string_literal: true

require 'zlib'
require 'rubygems/package'

# base class
class ApplicationController < ActionController::Base
  rescue_from Exception, with: :send_error

  def not_found(exception = nil)
    if exception
      logger.error("404: rescued_from: #{print_exception(exception)}
")
    end
    render(
      template: 'errors/not_found_error',
      layout: 'layouts/application',
      status: :not_found
    )
  end

  def send_error(exception)
    if exception.is_a?(ActionController::RoutingError) ||
       exception.is_a?(ActiveRecord::RecordNotFound)
      not_found(exception)
    else
      render_error(exception)
    end
  end

  def render_error(exception)
    error_string =
      "500: rescued_from:
      #{print_exception(exception)}"
    logger.error(error_string)
    render(
      template: 'errors/internal_server_error',
      layout: 'layouts/application',
      status: '500',
      formats: [:html]
    )
  end

  include ActionController::HttpAuthentication::Basic::ControllerMethods
  protect_from_forgery with: :exception
  before_action :set_announcement
  before_action :check_auth
  helper_method :scoped_resources
  helper_method :scoped_blog

  def robots
    robots = File.read(Rails.root + "config/robots/#{Rails.env}.txt")
    render plain: robots
  end

  private

  def print_exception(exception)
    "#{params[:controller]}##{params[:action]}:
    #{exception.inspect}\n#{exception.backtrace[0..50]}\n"
  end

  def check_auth
    session[:preview] = false
    return unless request.base_url.to_s.match?('preview')

    http_authenticate
  end

  def http_authenticate
    authenticate_or_request_with_http_basic do |username, password|
      (username == Rails.application.credentials[:preview][:name]) &&
        (password == Rails.application.credentials[:preview][:password])
      session[:preview] = true
    end
  end

  def scoped_resources
    if session[:preview]
      SiteItem.preview.displayed
    else
      SiteItem.published.displayed
    end
  end

  def set_announcement
    @announcement = Announcement.displayed.for_today.first
  end

  def process_message(contact)
    flash.delete(:error)
    flash.delete(:notice)
    contact.request = request
    if contact.deliver
      flash[:notice] = 'Thank you for your message!'
    else
      flash[:error] =
        "Error: message not sent! #{contact.errors.full_messages.to_sentence}"
    end
  end
end
