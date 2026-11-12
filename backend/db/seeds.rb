if Rails.env.development? && ENV["DEMO_PASSWORD"].present?
  # Explicit opt-in: never create a known-password account during setup or in production.
  password = ENV["DEMO_PASSWORD"]
  abort "Set DEMO_PASSWORD (12–128 characters) to create local demo accounts." unless password && password.length.between?(12, 128)

  User.transaction do
    accounts = [["owner@homeharbor.test", "Propietario demo"], ["guest@homeharbor.test", "Visitante demo"]].map do |email, name|
      User.find_or_create_by!(email: email) do |user|
        user.name = name
        user.password = password
        user.password_confirmation = password
        user.skip_confirmation!
      end
    end
    owner = accounts.first
    [
      { name: "Brisa del Delta", port: "Tigre", capacity: 6, daily_rate_cents: 12000 },
      { name: "Horizonte", port: "San Fernando", capacity: 10, daily_rate_cents: 24000 },
      { name: "Sur", port: "Tigre", capacity: 3, daily_rate_cents: 8000 }
    ].each do |attributes|
      owner.boats.find_or_create_by!(name: attributes[:name]) do |boat|
        boat.assign_attributes(attributes.merge(description: "Bote ficticio para probar Homeharbor. No representa una oferta comercial.",
          currency: "USD", time_zone: Boat::TIME_ZONE))
      end
    end
  end
  puts "Demo ready: owner@homeharbor.test and guest@homeharbor.test. Existing passwords and boats were preserved."
elsif Rails.env.development?
  puts "Demo seeds skipped. Set DEMO_PASSWORD and run bin/rails db:seed to opt in."
else
  puts "Demo seeds skipped outside development."
end
