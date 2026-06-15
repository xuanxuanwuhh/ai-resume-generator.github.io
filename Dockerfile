FROM jekyll/builder:latest
WORKDIR /srv/jekyll
COPY Gemfile Gemfile.lock ./
RUN gem install bundler:2.6.9 && bundle _2.6.9_ config set frozen true && bundle _2.6.9_ install --jobs 4 --retry 5
COPY . .
EXPOSE 4000
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--port", "4000"]
