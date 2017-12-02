class ShipmentsController < ApplicationController
  
  # before_action do 
  #   require_login("user")
  # end
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }
  
  def init_shipment
    @Shipment ||= Shipment.new
  end
  
  def new
    @shipment = Shipment.new
  end
  
  def get_location_details()
    lat = params[:lat]
    lng = params[:lng]
    geocode = JSON.parse Net::HTTP.get(URI.parse("https://maps.googleapis.com/maps/api/geocode/json?latlng="+ lat +"," + lng + "&key=AIzaSyCULAfBJit219O85L4mwt4nqVhBL9KARCQ"))
    
    addresses = geocode["results"][0]["address_components"]
    number = ''
    address = ''
    addresses.each { |adr|
      if adr["types"][0] == "route"
        address = adr["long_name"]
      elsif adr["types"][0] == "street_number"
        number = adr["long_name"]
      end
    }
    
    render json: {street: address, number: number}
    #return Location.new(lat: lat, long: lng, street: address, number: number, zipcode: zipcode)
  end
  
  def create
    driver_id = params[:driver_id]
    cant = Shipment.where(driver_id: driver_id, state: 'In Progress')
    if cant.length > 0 
      render json: {:status => 400, :message => 'This driver is unavailable' }
    else
      @Shipment = Shipment.new()
      @Shipment.payment = params[:payment]
      @Shipment.weight = params[:weight]
      @Shipment.origin_lat = params[:originLat]
      @Shipment.origin_lng = params[:originLng]
      @Shipment.destination_lat = params[:destinationLat]
      @Shipment.destination_lng = params[:destinationLng]
      @Shipment.state = 'In Progress'
      @Shipment.date = DateTime.now
      @Shipment.sender_id = params[:sender]
      @Shipment.driver_id = driver_id
      @Shipment.price = params[:price_per_kilo] * @Shipment.weight
      
      if params[:has_discount] != '0'
        @Shipment.price = @Shipment.price / 2
      end

      # @Shipment.driver.save(validate: false)
      
      if @Shipment.save
        render json: {status: 200}
        flash[:success] = "Success!"
      else
        render json: {status: 400, :message => 'The shipment cant be saved, try later men'}
      end
    end
  end
  
  
  def get_drivers_in_progress_shipments
    current_driver = params[:driver_id]
    @shipment_in_progress = Shipment.where(:state => 'In Progress' , :driver_id => current_driver) 
    render json: @shipment_in_progress
  end
  
  def get_drivers_delivered_shipments
    current_driver = params[:driver_id]
    @shipment_deliveder = Shipment.where(:state => 'Delivered', :driver_id => current_driver) 
    render json: @shipment_deliveder
  end
  
  def details
    originLat = params[:originLat]
    originLng = params[:originLng]
    destinationLat = params[:destinationLat]
    destinationLng = params[:destinationLng]
    body = '?originLat=' + originLat + '&originLng=' + originLng
    uri = 'drivers/nearby' + body
    drivers = Faraday.get(ENV['URL_APP'] + uri)
    price_per_kilo = calculate_price_per_kg
    redirect_to ENV['URL_APP'] + 'shipments/details?originLat=' + originLat + '&originLng=' + originLng + '&destinationLat=' + destinationLat + '&destinationLng=' + destinationLng + '&price=' + price_per_kilo.to_s + '&drivers=' + (JSON.parse(drivers.body).to_s)
  end
  
  def find_shipment_by_id
    shipment = Shipment.find_by_id(params[:id])
    render json: shipment
  end
  
  def end_shipment
    shipment = Shipment.find_by_id(params[:shipment_id])
    shipment.state = 'Delivered'
    if shipment.save
      render json: { :status => 200 }
    else
      render json: { :status => 400, :message => 'something went wrong' }
    end
      

    # UserMailer.confirmation_email(@Shipment).deliver_later
    # redirect_to '/drivers/shipment_list'
  end
  

  private
    
      def calculate_price_per_kg
        url_api = ENV['URLAPIKG']
        user = ENV['USERAPI']
        pass = ENV['PASSWORDAPI']
        conn = Faraday.new(url: url_api) 
        conn.basic_auth(user, pass)
        JSON.parse(conn.get('/cost').body)["cost"]
      end
  
end
