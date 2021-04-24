class CreateSpreePaySimpleCheckout < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_pay_simple_checkouts do |t|
      t.string :payment_token
      t.string :account_id
      t.string :transaction_id, index: true
      t.string :state, default: "complete", index: true
      t.string :name
      t.integer :user_id
      t.integer :payment_method_id
      t.timestamps null: false
    end
  end
end
