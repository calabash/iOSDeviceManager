#!/usr/bin/env groovy

pipeline {
  agent { label 'master' }

  environment {
    DEVELOPER_DIR = '/Xcode/9.2/Xcode.app/Contents/Developer'

    SLACK_COLOR_DANGER  = '#E01563'
    SLACK_COLOR_INFO    = '#6ECADC'
    SLACK_COLOR_WARNING = '#FFC300'
    SLACK_COLOR_GOOD    = '#3EB991'

    PROJECT_NAME = 'iOSDeviceManager'
  }

  stages {
    stage('Announce') {
      steps {
        slackSend (color: "${env.SLACK_COLOR_INFO}",
                  message: "${env.PROJECT_NAME} [${env.GIT_BRANCH}] #${env.BUILD_NUMBER} *Started* (<${env.BUILD_URL}|Open>)")
      }
    }
    stage('Run build and tests') {
      steps {
        sh 'gtimeout --signal SIGKILL 75m bin/test/ci.sh'
      }
    }
  }

  post {
    always {
      junit 'reports/*.xml'
    }

    aborted {
      echo "Sending 'aborted' message to Slack"
      slackSend (color: "${env.SLACK_COLOR_WARNING}",
                message: "${env.PROJECT_NAME} [${env.GIT_BRANCH}] #${env.BUILD_NUMBER} *Aborted* after ${currentBuild.durationString.replace('and counting', '')}(<${env.BUILD_URL}|Open>)")
    }

    failure {
      echo "Sending 'failed' message to Slack"
      slackSend (color: "${env.SLACK_COLOR_DANGER}",
                message: "${env.PROJECT_NAME} [${env.GIT_BRANCH}] #${env.BUILD_NUMBER} *Failed* after ${currentBuild.durationString.replace('and counting', '')}(<${env.BUILD_URL}|Open>)")
    }

    success {
      echo "Sending 'success' message to Slack"
      slackSend (color: "${env.SLACK_COLOR_GOOD}",
                message: "${env.PROJECT_NAME} [${env.GIT_BRANCH}] #${env.BUILD_NUMBER} *Success* after ${currentBuild.durationString.replace('and counting', '')}(<${env.BUILD_URL}|Open>)")
    }
  }

  options {
    disableConcurrentBuilds()
    timestamps()
  }
}
