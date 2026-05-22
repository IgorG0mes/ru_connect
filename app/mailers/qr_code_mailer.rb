require "rqrcode"

class QrCodeMailer < ApplicationMailer
  def send_qr_code(person)
    @person = person
    attach_qr_png(person)
    mail(to: person.email, subject: t(".subject", name: person.name))
  end

  def welcome(person)
    @person = person
    attach_qr_png(person)
    mail(to: person.email, subject: t(".subject", name: person.name))
  end

  def qr_code_regenerated(person)
    @person = person
    attach_qr_png(person)
    mail(to: person.email, subject: t(".subject", name: person.name))
  end

  private

  def attach_qr_png(person)
    png = RQRCode::QRCode.new(person.qr_code_hash).as_png(size: 300, border_modules: 2)
    attachments.inline["qr_code.png"] = { mime_type: "image/png", content: png.to_s }
  end
end
