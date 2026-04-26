class Role < ApplicationRecord
  has_many :permissions, dependent: :destroy
end
