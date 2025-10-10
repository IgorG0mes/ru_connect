class AccessLog < ApplicationRecord
  belongs_to :personable, polymorphic: true
  enum :status, [ :allowed, :denied, :warning ]
  validates :status, presence: true

  def identifier
    if personable_type == "Student"
      personable.registration.presence || personable.cpf
    elsif personable_type == "Visitor"
      personable.cpf.presence || personable.name
    else
      "N/A"
    end
  end

  def person_name
    personable.name
  rescue
    "Pessoa Desconhecida"
  end

  def course_name
    personable.course
  rescue
    "Visitante"
  end
end
