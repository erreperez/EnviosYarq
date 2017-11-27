class ShipmentsController < ApplicationController
  
  # before_action do 
  #   require_login("user")
  # end
  
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
    pp 'llegaranskinski'
    @Shipment = Shipment.new(user_params)
    originLoc = create_location(params[:originLat], params[:originLng])
    destinationLoc = create_location(params[:destinationLat], params[:destinationLng])
    originLoc.save
    destinationLoc.save
    @Shipment.origin = originLoc
    @Shipment.destination = destinationLoc
    @Shipment.state = 'In Progress'
    @Shipment.date = DateTime.now
    @Shipment.sender = current_user
    @Shipment.driver = Driver.find_by_id(params[:shipment][:driver])
    @Shipment.price = params[:price_per_kilo] * @Shipment.weight
    
    @user = User.find_by_id(current_user.id)
    
    if @user.discounts > 0
      @Shipment.price = @Shipment.price / 2
      @user.discounts -= 1
      @user.save(validate: false)
    end
    
    if current_user.new_user
      if current_user.invitee != nil
        @invitee = User.find_by_id(current_user.invitee)
        @invitee.discounts = @invitee.discounts + 1
        @invitee.save(validate: false)
      end
      @user.new_user = false
      @user.save(validate: false)
    end
    
    @Shipment.driver.available = false;
    @Shipment.driver.save(validate: false)
    
    
    receiver = User.find_by_email(params[:receiver])
    if receiver != nil
      @Shipment.receiver = receiver
    else 
      receiver = User.new do |u|
        u.email = params[:receiver]
        u.name = "a"
        u.password = "12345678"
      end
      receiver.save
      @Shipment.receiver = receiver
      UserMailer.welcome_email(@Shipment.receiver.email, @Shipment.sender.id).deliver_later
    end
    if @Shipment.save
      redirect_to root_path
      flash[:success] = "Success!"
    else
      flash[:danger] = 'error'
    end
  end
  
  
  def get_drivers_in_progress_shipments
    current_driver = params[:driver]
    @shipment_in_progress = Shipment.where(:state => 'In Progress' , :driver_id => current_driver) 
    pp "ca;o", current_driver,  @shipment_in_progress
    render json: @shipment_in_progress
  end
  
  def get_drivers_delivered_shipments
    current_driver = params[:driverId]
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
    pp 'vamo arruca', drivers
    redirect_to (ENV['URL_APP'] + 'shipment/details?originLat=' + originLat + '&originLng=' + originLng + '&destinationLat=' + destinationLat + '&destinationLng=' + destinationLng + '&price=' + price_per_kilo.to_s + '&drivers=' + JSON.parse(drivers.body).to_s)
  end
  

  private
    
    def user_params
      params.require(:shipment).permit(:weight, :payment)
    end
    
      def calculate_price_per_kg
        url_api = ENV['URLAPIKG']
        user = ENV['USERAPI']
        pass = ENV['PASSWORDAPI']
        conn = Faraday.new(url: url_api) 
        conn.basic_auth(user, pass)
        # JSON.parse(conn.get('/cost').body)["cost"]
        return 20
      end
  
end
