class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true
  
  def routing_error
    render :file => 'public/404.html', :status => 404, :layout => false, head: 404
  end
end
