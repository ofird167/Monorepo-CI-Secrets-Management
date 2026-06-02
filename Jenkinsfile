pipeline {
  agent any

  options {
    timeout(time: 1, unit: 'HOURS')
    buildDiscarder(logRotator(numToKeepStr: '10'))
    disableConcurrentBuilds()
  }

  environment {
    // AWS S3 bucket holding project secrets
    AWS_S3_BUCKET    = 'devops-s3-state-bucket'
    
    // Fallback if GIT_COMMIT is not populated in a local shell runner
    SHORT_SHA        = "${env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : 'latest'}"
    
    // Holds the list of modified microservices
    CHANGED_SERVICES = ""
  }

  stages {
    stage('Detect Changes') {
      steps {
        script {
          // Detect changes against the target branch for a PR or the previous commit for a push.
          def baseRef = env.CHANGE_TARGET ?: "HEAD~1"
          
          // Make sure CI scripts are executable
          sh "chmod +x shared/ci/*.sh shared/aws/*.sh"
          
          // Execute changes detector script
          CHANGED_SERVICES = sh(
            script: "./shared/ci/detect_changes.sh ${baseRef}",
            returnStdout: true
          ).trim()
          
          echo "Services with modified files: [${CHANGED_SERVICES}]"
        }
      }
    }

    stage('Parallel Quality & SAST') {
      parallel {
        stage('User Service Quality') {
          when {
            expression { CHANGED_SERVICES.contains('user-service') }
          }
          steps {
            retry(2) {
              sh "./shared/ci/lint.sh user-service"
            }
            sh "./shared/ci/scan.sh user-service"
          }
        }
        
        stage('Transaction Service Quality') {
          when {
            expression { CHANGED_SERVICES.contains('transaction-service') }
          }
          steps {
            retry(2) {
              sh "./shared/ci/lint.sh transaction-service"
            }
            sh "./shared/ci/scan.sh transaction-service"
          }
        }
        
        stage('Notification Service Quality') {
          when {
            expression { CHANGED_SERVICES.contains('notification-service') }
          }
          steps {
            retry(2) {
              sh "./shared/ci/lint.sh notification-service"
            }
            sh "./shared/ci/scan.sh notification-service"
          }
        }
      }
    }

    stage('Parallel Unit Testing') {
      parallel {
        stage('User Service Tests') {
          when {
            expression { CHANGED_SERVICES.contains('user-service') }
          }
          steps {
            sh "./shared/ci/test.sh user-service"
            // Collect and publish JUnit reports
            junit allowEmptyResults: true, testResults: 'user-service/junit.xml'
          }
        }
        
        stage('Transaction Service Tests') {
          when {
            expression { CHANGED_SERVICES.contains('transaction-service') }
          }
          steps {
            sh "./shared/ci/test.sh transaction-service"
            junit allowEmptyResults: true, testResults: 'transaction-service/report.xml'
          }
        }
        
        stage('Notification Service Tests') {
          when {
            expression { CHANGED_SERVICES.contains('notification-service') }
          }
          steps {
            sh "./shared/ci/test.sh notification-service"
          }
        }
      }
    }

    stage('Parallel Docker Build') {
      parallel {
        stage('User Service Image') {
          when {
            expression { CHANGED_SERVICES.contains('user-service') }
          }
          steps {
            retry(2) {
              echo "Building User Service Docker Image..."
              sh "docker build -t user-service:ci-${SHORT_SHA} user-service/"
              // Optional: Push to registry
              // sh "docker push user-service:ci-${SHORT_SHA}"
            }
          }
        }
        
        stage('Transaction Service Image') {
          when {
            expression { CHANGED_SERVICES.contains('transaction-service') }
          }
          steps {
            retry(2) {
              echo "Building Transaction Service Docker Image..."
              sh "docker build -t transaction-service:ci-${SHORT_SHA} transaction-service/"
              // Optional: Push to registry
              // sh "docker push transaction-service:ci-${SHORT_SHA}"
            }
          }
        }
        
        stage('Notification Service Image') {
          when {
            expression { CHANGED_SERVICES.contains('notification-service') }
          }
          steps {
            retry(2) {
              echo "Building Notification Service Docker Image..."
              sh "docker build -t notification-service:ci-${SHORT_SHA} notification-service/"
              // Optional: Push to registry
              // sh "docker push notification-service:ci-${SHORT_SHA}"
            }
          }
        }
      }
    }

    stage('Deploy Manual Gate') {
      steps {
        // Pauses build execution requesting developer approval before success status
        input message: 'Approve deployment of built microservice Docker images?', ok: 'Deploy'
      }
    }

    stage('Promote CD Trigger') {
      steps {
        echo "Release artifact promo hook: Images tag ci-${SHORT_SHA} deployed successfully."
      }
    }
  }

  post {
    always {
      // Cleans up the Jenkins node workspace to save disk space and remove transient logs
      cleanWs()
    }
    success {
      echo "Jenkins CI Pipeline execution completed successfully."
      // Example webhook notification send:
      // slackSend channel: '#ci-deploy', color: '#00FF00', message: "SUCCESS: Job '${env.JOB_NAME}' [${env.BUILD_NUMBER}] completed successfully."
    }
    failure {
      echo "Jenkins CI Pipeline execution failed."
      // Example webhook notification send:
      // slackSend channel: '#ci-deploy', color: '#FF0000', message: "FAILURE: Job '${env.JOB_NAME}' [${env.BUILD_NUMBER}] failed."
    }
  }
}
