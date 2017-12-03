class ShipmentMailer < ApplicationMailer
    
    default from: 'enviosyarq@gmail.com'
    
    def confirmation_email(shipment, sender_email, receiver_email)
        @shipment = shipment
        @sender_email = sender_email
        @receiver_email = receiver_email
        @origin = JSON.parse(Faraday.get(ENV['URL_SHIPMENT'] + 'get_address?lat=' + @shipment['origin_lat'].to_s + '&lng=' + @shipment['origin_lng'].to_s).body)
        @destination = JSON.parse(Faraday.get(ENV['URL_SHIPMENT'] + 'get_address?lat=' + @shipment['destination_lat'].to_s + '&lng=' + @shipment['destination_lng'].to_s).body)
        mail(to: @receiver_email, subject: 'The shipment arrived!')
        mail(to: @sender_email, subject: 'The shipment arrived!')
    end
    
end