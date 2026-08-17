
FROM ruby:3.4.6-slim

ENV RAILS_ENV=development \
    BUNDLE_PATH=/bundle \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm libyaml-dev postgresql-client && \
    npm install -g yarn

WORKDIR /usr/src/app

RUN gem install bundler

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /usr/src/app /bundle
USER rails:rails

ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
