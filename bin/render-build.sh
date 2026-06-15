#!/usr/bin/env bash
# Build script executado pelo Render a cada deploy.
# https://render.com/docs/deploy-rails
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean

# Banco primary: cria (se necessario) e roda as migrations da aplicação.
bundle exec rails db:prepare

# O stack Solid (Queue/Cache/Cable) usa arquivos db/*_schema.rb, não migrations.
# No Render o banco já vem criado, então o db:prepare acima NÃO carrega esses
# schemas. Carregamos manualmente — só quando a tabela marcadora ainda não
# existe, deixando o passo idempotente entre deploys.
load_solid_schema() {
  local db_name="$1" marker="$2"
  if bundle exec rails runner "exit(ActiveRecord::Base.connection.table_exists?('$marker') ? 0 : 1)"; then
    echo "==> ${marker} já existe — pulando schema de ${db_name}."
  else
    echo "==> Carregando schema do banco ${db_name}..."
    # schema:load é tratado como destrutivo pelo Rails em produção; liberamos a
    # checagem porque só chegamos aqui quando a tabela ainda NÃO existe.
    DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails "db:schema:load:${db_name}"
  fi
}

load_solid_schema queue solid_queue_jobs
load_solid_schema cache solid_cache_entries
load_solid_schema cable solid_cable_messages
