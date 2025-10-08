puts "Criando Role Admin..."
admin_role = Role.find_or_create_by!(name: 'admin')

# 2. RECRIAR O USUÁRIO OPERADOR
puts "Criando Usuário Operador..."
User.find_or_create_by!(email: 'igor@ru.com') do |user|
  user.password = 'password'
  user.username = 'igor.gomes'
  user.role = admin_role
end
