FROM ruby:3.1-slim

WORKDIR /app
RUN gem install bundler
COPY Gemfile Gemfile.lock /app/
RUN bundle install

COPY . .
CMD [ "ruby", "bot.rb" ]