class ShipmentsController < ApplicationController
  
  before_action :init_shipment
  # before_action do 
  #   require_login("user")
  # end
  
  def init_shipment
    @Shipment ||= Shipment.new
  end
  
  def new
    @shipment = Shipment.new
  end
  
  def details
    @near_drivers = get_near_drivers(params[:originLat], params[:originLng])
    if @near_drivers.length==0
      flash[:danger] = 'No hay drivers disponibles en este momento'
      redirect_to root_path
    else
      originLoc = create_location(params[:originLat], params[:originLng])
      destinationLoc = create_location(params[:destinationLat], params[:destinationLng])
      @Shipment.origin = originLoc
      @Shipment.destination = destinationLoc
      # @halfShipment = params[:shipment]
      @price_per_kilo = calculate_price_per_kg
      # @details = 
      
      
      obj = {drivers: @near_drivers, price: @price_per_kilo }
      pp obj
      
    end
  end
  
  def create
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
    pp "shipments", current_driver,  @shipment_in_progress
    render json: @shipment_in_progress
  end
  
  def get_drivers_delivered_shipments
    current_driver = params[:driverId]
    @shipment_deliveder = Shipment.where(:state => 'Delivered', :driver_id => current_driver) 
    render json: @shipment_deliveder
  end

  private
    
    def user_params
      params.require(:shipment).permit(:weight, :payment)
    end
    
    def get_near_drivers(lat, lng)
      driver1, driver2, driver3 = nil
      d1, d2, d3 = nil
      Driver.includes(:location).all.each do |d|
        if d.available
          distance = Geocoder::Calculations.distance_between([lat.to_f,lng.to_f], [d.location.lat,d.location.long])
          if d3 == nil || distance < d3
            if d2 == nil || distance < d2
              if d1 == nil || distance < d1
                d3 = d2 
                driver3 = driver2
                d2 = d1
                driver2 = driver1
                d1 = distance
                driver1 = d
              else
                d3 = d2
                driver3 = driver2
                d2 = distance
                driver2 = d
              end
            else
              d3 = distance
              driver3 = d
            end
          end
        end
      end
      near_drivers = []
      near_drivers << driver1 unless driver1.nil?
      near_drivers << driver2 unless driver2.nil?
      near_drivers << driver3 unless driver3.nil?
      return near_drivers
    end
    
      def calculate_price_per_kg
        url_api = ENV['URLAPIKG']
        user = ENV['USERAPI']
        pass = ENV['PASSWORDAPI']
        conn = Faraday.new(url: url_api) 
        conn.basic_auth(user, pass)
        JSON.parse(conn.get('/cost').body)["cost"]
      end
  
end
