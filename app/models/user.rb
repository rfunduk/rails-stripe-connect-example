class User < ActiveRecord::Base
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  has_secure_password

  def connected?
    !stripe_user_id.nil?
  end
end
