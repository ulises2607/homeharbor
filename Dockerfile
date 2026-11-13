# syntax=docker/dockerfile:1
FROM node:26.13.1-slim AS frontend
WORKDIR /frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM ruby:4.0.9-slim AS gems
WORKDIR /rails
ENV BUNDLE_PATH=/usr/local/bundle BUNDLE_WITHOUT=development:test BUNDLE_DEPLOYMENT=1 RAILS_ENV=production
RUN apt-get update -qq && apt-get install --no-install-recommends -y build-essential libpq-dev git pkg-config && rm -rf /var/lib/apt/lists/*
COPY backend/Gemfile backend/Gemfile.lock ./
RUN gem install bundler -v 4.0.20 && bundle install && rm -rf /usr/local/bundle/ruby/*/cache
COPY backend/ ./
RUN SECRET_KEY_BASE_DUMMY=1 ruby bin/rails assets:precompile
COPY --from=frontend /frontend/dist/ ./public/

FROM ruby:4.0.9-slim
WORKDIR /rails
ENV BUNDLE_PATH=/usr/local/bundle BUNDLE_WITHOUT=development:test BUNDLE_DEPLOYMENT=1 RAILS_ENV=production RAILS_SERVE_STATIC_FILES=true
RUN apt-get update -qq && apt-get install --no-install-recommends -y libpq5 curl && rm -rf /var/lib/apt/lists/* && useradd --create-home rails
COPY --from=gems /usr/local/bundle /usr/local/bundle
COPY --from=gems /rails /rails
RUN mkdir -p log tmp storage && chown -R rails:rails log tmp storage
USER rails
EXPOSE 3000
CMD ["ruby", "bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
