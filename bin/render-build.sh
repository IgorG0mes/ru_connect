#!/usr/bin/env bash
# Build script executado pelo Render a cada deploy.
# https://render.com/docs/deploy-rails
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean

# db:prepare cria o banco (se necessario) e roda as migrations de todos os
# bancos configurados em produção: primary, cache, queue e cable (Solid *).
bundle exec rails db:prepare
