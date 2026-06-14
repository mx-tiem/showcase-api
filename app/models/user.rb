class User < ApplicationRecord
  extend Enumerize
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  # Virtual attribute for authenticating by either email or username
  attr_accessor :login

  has_many :reservations
  has_many :machine_hours
  has_many :friends
  has_many :game_plays
  has_many :games, through: :game_plays
  has_many :notifications, dependent: :destroy

  enumerize :role, in: [ :user, :admin ], default: :user

  def available_playhours
    machine_hours
      .where(hours_type: :playhours)
      .where(hours_status: :active)
      .where("expires = ? OR (expires = ? AND expires_at > ?)", false, true, Time.current)
      .sum(:hours_amount)
  end

  def current_and_future_reservations
    Reservation.current_and_future(self)
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where(
        "lower(email) = :value OR lower(username) = :value",
        value: login.strip.downcase
      ).first
    elsif conditions.has_key?(:email)
      where(conditions.to_h).first
    elsif conditions.has_key?(:username)
      where(conditions.to_h).first
    end
  end
end
