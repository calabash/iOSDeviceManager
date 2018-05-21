String cron_string = BRANCH_NAME == "develop" ? "H H(0-8) * * *" : ""

pipeline {
  agent { label 'master' }
  triggers { cron(cron_string) }

  environment {
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
    stage('Prepare CI env') {
      steps {
        sh 'bin/test/ci.sh'
      }
    }
    stage('Test') {
      steps {
        sh 'make tests'
      }
    }
  }

  post {
    always {
      // Ignore errors on post step to prevent build failing
      sh '''
        pkill iOSDeviceManager || true
        pkill Simulator || true
      '''
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
    timeout(time: 60, unit: 'MINUTES')
    timestamps()
  }
}
