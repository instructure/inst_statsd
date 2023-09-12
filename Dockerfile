FROM instructure/ruby:2.7

ENV LC_ALL C.UTF-8

COPY --chown=docker:docker . /usr/src/app/

USER docker

ENV BUNDLER_VERSION 2.4.19
ENV RAILS_ENV test
RUN gem install bundler -v 2.4.19 && bundle install -j 4
