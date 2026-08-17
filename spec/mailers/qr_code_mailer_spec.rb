require "rails_helper"

RSpec.describe QrCodeMailer, type: :mailer do
  let(:student) do
    Student.create!(
      name:         "João Silva",
      cpf:          CPF.generate(stripped: true),
      registration: "REG_#{SecureRandom.hex(4)}",
      email:        "joao@example.com",
      course:       "Engenharia",
      status:       "active"
    )
  end

  shared_examples "a qr code email" do |method, expected_subject_fragment|
    subject(:mail) { QrCodeMailer.public_send(method, student) }

    it "sends to the person's email" do
      expect(mail.to).to eq(["joao@example.com"])
    end

    it "includes the person's name in the subject" do
      expect(mail.subject).to include("João Silva")
    end

    it "includes the expected subject fragment" do
      expect(mail.subject).to include(expected_subject_fragment)
    end

    it "attaches the QR Code PNG inline" do
      inline = mail.attachments.select(&:inline?)
      expect(inline).not_to be_empty
      expect(inline.first.filename).to eq("qr_code.png")
      expect(inline.first.content_type).to include("image/png")
    end

    it "renders the HTML part" do
      html = all_parts(mail).find { |p| p.content_type.include?("text/html") }
      expect(html).to be_present
      expect(html.body.encoded).to include(student.qr_code_hash)
    end

    it "renders the text part" do
      text = all_parts(mail).find { |p| p.content_type.include?("text/plain") }
      expect(text).to be_present
      expect(text.body.encoded).to include(student.qr_code_hash)
    end
  end

  describe "#welcome" do
    include_examples "a qr code email", :welcome, "Bem-vindo"
  end

  describe "#send_qr_code" do
    include_examples "a qr code email", :send_qr_code, "QR Code de Acesso"
  end

  describe "#qr_code_regenerated" do
    include_examples "a qr code email", :qr_code_regenerated, "novo QR Code"

    it "mentions the invalidation in the HTML body" do
      mail = QrCodeMailer.qr_code_regenerated(student)
      html = all_parts(mail).find { |p| p.content_type.include?("text/html") }
      expect(html.body.encoded).to include("invalidado")
    end
  end

  def all_parts(mail)
    mail.parts.flat_map { |p| p.multipart? ? p.parts : p }
  end
end
