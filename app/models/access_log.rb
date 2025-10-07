class AccessLog < ApplicationRecord
  belongs_to :personable, polymorphic: true
  enum :status, [ :allowed, :denied, :warning ]
  validates :status, presence: true
end
