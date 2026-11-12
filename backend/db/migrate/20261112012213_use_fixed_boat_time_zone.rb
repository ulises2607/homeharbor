class UseFixedBoatTimeZone < ActiveRecord::Migration[8.1]
  def up
    change_column_default :boats, :time_zone, from: "America/Argentina/Buenos_Aires", to: "Etc/GMT+3"
    execute "UPDATE boats SET time_zone = 'Etc/GMT+3'"
    add_check_constraint :boats, "currency = 'USD'", name: "boats_usd_currency"
    add_check_constraint :boats, "time_zone = 'Etc/GMT+3'", name: "boats_fixed_time_zone"
  end

  def down
    # Previous per-boat zones cannot be recovered after adopting a global zone.
    raise ActiveRecord::IrreversibleMigration, "Restore a backup to recover previous boat time zones"
  end
end
