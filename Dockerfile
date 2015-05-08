FROM ruby:2.1.2

ENV LC_ALL C.UTF-8

RUN apt-get update

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ADD . /usr/src/app/

ENV RAILS_ENV test
RUN bundle install --system

