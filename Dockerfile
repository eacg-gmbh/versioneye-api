FROM        versioneye/ruby-base:1.9.2
MAINTAINER  Robert Reiz <reiz@versioneye.com>

ADD . /app

RUN bundle install

EXPOSE 9090

CMD bundle exec puma -C config/puma.rb
