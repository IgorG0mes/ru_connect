class Role < ApplicationRecord
  has_many :permissions, dependent: :destroy
  validates :name, presence: true, uniqueness: true
end
