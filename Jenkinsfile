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
    stage('Test') {
      steps {
        sh 'docker run --rm inst_statsd bundle exec appraisal rspec spec'
      }
    }
  }

  post {
    success {
      dockerCacheStore(image: 'inst_statsd')
    }
  }
}
