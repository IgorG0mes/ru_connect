class QrCodeGeneratorService
  def self.generate_and_assign(person)
    unique_hash = SecureRandom.hex(5).upcase
    person.update!(qr_code_hash: unique_hash)
  end
end
