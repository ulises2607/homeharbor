# == Schema Information
#
# Table name: listings
#
#  id            :bigint           not null, primary key
#  hosts_id      :bigint           not null
#  title         :string           not null
#  about         :text
#  max_guests    :integer          default(1)
#  address_line1 :string
#  address_line2 :string
#  city          :string
#  state         :string
#  postal_code   :string
#  country       :string
#  lat           :decimal(10, 6)
#  lng           :decimal(10, 6)
#  status        :integer          default(0)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Listing < ApplicationRecord
    belongs_to :host, class_name: 'User'
end