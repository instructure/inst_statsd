FROM instructure/ruby:2.5

ENV LC_ALL C.UTF-8
ENV APP_HOME "/usr/src/app/"

USER root

RUN apt-get update

RUN mkdir -p $APP_HOME

COPY --chown=docker:docker . $APP_HOME/

USER docker

ENV RAILS_ENV test
RUN bundle install --system
RUN bundle exec appraisal install

