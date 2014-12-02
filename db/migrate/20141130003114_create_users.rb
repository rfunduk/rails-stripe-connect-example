class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :password_digest

      t.string :publishable_key
      t.string :secret_key
      t.string :stripe_user_id
      t.string :currency

      t.timestamps
    end
  end
end
