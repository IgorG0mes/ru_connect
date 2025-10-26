# puts "Criando Role Admin..."
# admin_role = Role.find_or_create_by!(name: 'admin')

# puts "Criando Usuário Operador..."
# User.find_or_create_by!(email: 'igor@ru.com') do |user|
#   user.password = 'password'
#   user.username = 'igor.gomes'
#   user.role = admin_role
# end

require 'cpf_cnpj'
require 'faker'

NUM_RECORDS = 1000
COURSES = ['Medicina', 'Psicologia', 'Educação Física', 'Terapia Ocupacional', 'Enfermagem']

def generate_valid_cpf
  3.times do
    cpf = CPF.generate(true)
    return cpf if CPF.valid?(cpf)
  end

  CPF.generate(true)
end

puts "\n--- 1. CRIAÇÃO DE #{NUM_RECORDS} ALUNOS (Students) ---"
(1..NUM_RECORDS).each do |i|
  name = Faker::Name.name
  registration = (202512307 + i).to_s

  Student.find_or_create_by!(registration: registration) do |student|
    student.name = name
    student.cpf = generate_valid_cpf.gsub(/[^0-9]/, '')
    student.email = Faker::Internet.unique.email(name: name.gsub(/\s+/, ".").downcase)
    student.course = COURSES.sample
  end
  print "." if i % 100 == 0
end
puts "\n   -> #{NUM_RECORDS} Alunos criados."

puts "\n--- 2. CRIAÇÃO DE #{NUM_RECORDS} VISITANTES (Visitors) ---"
(1..NUM_RECORDS).each do |i|
  name = Faker::Name.name

  Visitor.find_or_create_by!(cpf: generate_valid_cpf) do |visitor|
    visitor.name = name
    visitor.email = Faker::Internet.unique.email(name: name.gsub(/\s+/, ".").downcase)
  end
  print "." if i % 100 == 0
end
puts "\n   -> #{NUM_RECORDS} Visitantes criados."

puts "\n--- SCRIPT DE SEEDING CONCLUÍDO ---"
