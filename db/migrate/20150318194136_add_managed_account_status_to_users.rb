class AddManagedAccountStatusToUsers < ActiveRecord::Migration
  def change
    add_column :users, :stripe_account_status, :text, default: '{}'
  end
end
