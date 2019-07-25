FROM instructure/ruby:2.5

ENV LC_ALL C.UTF-8

COPY --chown=docker:docker . /usr/src/app/

USER docker

ENV RAILS_ENV test
RUN bundle install -j 4
RUN bundle exec appraisal install
