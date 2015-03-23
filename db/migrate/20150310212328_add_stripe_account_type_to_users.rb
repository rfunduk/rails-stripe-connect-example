class AddStripeAccountTypeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :stripe_account_type, :string
  end
end
