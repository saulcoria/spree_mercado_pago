class AddDniToSpreeAddress < ActiveRecord::Migration
  def change
    add_column :spree_addresses, :dni, :string
  end
end
