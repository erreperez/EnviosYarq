Rails.application.routes.draw do
  get 'shipments/new'
  
  get '/shipments/progress', to: 'shipments#get_drivers_in_progress_shipments'
  get '/shipments/delivered', to: 'shipments#get_drivers_delivered_shipments'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
