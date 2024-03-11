class ChangeHostsIdToHostIdInListings < ActiveRecord::Migration[7.1]
  def change
    rename_column :listings, :hosts_id, :host_id
  end
end
