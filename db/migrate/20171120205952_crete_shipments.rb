class CreteShipments < ActiveRecord::Migration[5.1]
  def change
    create_table :shipments do |t|
      t.integer :price
      t.date :date
      t.string :payment
      t.string :state
      t.integer :sender_id
      t.integer :receiver_id
      t.float :origin_lat
      t.float :origin_lng
      t.float :destination_lat
      t.float :destination_lng
      t.integer :driver_id
      t.float :weight

      t.timestamps
    end
  end
end
