class Visitor < ApplicationRecord
  has_many :access_logs, as: :personable
  after_create :generate_qr_code

  private
  def generate_qr_code
    QrCodeGeneratorService.generate_and_assign(self)
  end
end
