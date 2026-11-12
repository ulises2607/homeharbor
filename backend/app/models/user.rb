class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :validatable,
         :confirmable, :lockable

  has_many :boats, foreign_key: :owner_id, inverse_of: :owner, dependent: :restrict_with_error
  validates :name, presence: true, length: { maximum: 100 }
  validates :password_confirmation, presence: true, if: -> { password.present? }

  def public_profile
    { id: id, name: name, email: email }
  end
end
