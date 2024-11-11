#! /usr/bin/env groovy

pipeline {
  agent { label 'docker' }

  stages {
    stage('Build') {
      steps {
        dockerCacheLoad(image: 'inst_statsd')
        sh 'docker build -t inst_statsd .'
      }
    }

    stage('Lint') {
      steps {
        sh "docker run --rm inst_statsd bin/rubocop"
      }
    }

    stage('Test') {
      steps {
        sh 'docker run --rm -e BUNDLE_LOCKFILE=rails-6.0 inst_statsd bin/rspec'
        sh 'docker run --rm -e BUNDLE_LOCKFILE=rails-6.1 inst_statsd bin/rspec'
        sh 'docker run --rm -e BUNDLE_LOCKFILE=rails-7.0 inst_statsd bin/rspec'
        sh 'docker run --rm -e BUNDLE_LOCKFILE=Gemfile.lock inst_statsd bin/rspec'
      }
    }

    stage('Publish') {
      when {
        allOf {
          expression { GERRIT_BRANCH == "main" }
          environment name: "GERRIT_EVENT_TYPE", value: "change-merged"
        }
      }
      steps {
        withCredentials([string(credentialsId: 'rubygems-rw', variable: 'GEM_HOST_API_KEY')]) {
          sh 'docker run -e GEM_HOST_API_KEY --rm inst_statsd /bin/bash -lc "./bin/publish.sh"'
        }
      }
    }
  }

  post {
    success {
      dockerCacheStore(image: 'inst_statsd')
    }
  }
}
