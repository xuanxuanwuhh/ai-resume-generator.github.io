FROM jekyll/builder:latest

WORKDIR /srv/jekyll

COPY Gemfile .
COPY Gemfile.lock .

RUN bundle install

COPY . .

EXPOSE 4000

CMD ["jekyll", "serve", "--host", "0.0.0.0"]