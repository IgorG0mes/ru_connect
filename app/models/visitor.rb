require "rqrcode"

class Visitor < ApplicationRecord
  has_many :access_logs, as: :personable
  after_create :generate_qr_code

  def generate_qr_code_svg
    return unless qr_code_hash.present?

    qrcode = RQRCode::QRCode.new(qr_code_hash)

    qrcode.as_svg(
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 6,
      standalone: true,
      viewbox: "0 0 300 300"
    )
    .html_safe
  end

  private
  def generate_qr_code
    QrCodeGeneratorService.generate_and_assign(self)
  end
end
