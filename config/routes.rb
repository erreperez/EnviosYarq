Rails.application.routes.draw do
  get 'shipments/new'
  
  get '/in_progress', to: 'shipments#get_drivers_in_progress_shipments'
  get '/delivered', to: 'shipments#get_drivers_delivered_shipments'
  post '/details', to: 'shipments#details'
  post '/create', to: 'shipments#create'
  get '/get_address', to: 'shipments#get_location_details'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
