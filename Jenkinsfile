pipeline {
  agent any

  environment {
    DOCKER_IMAGE = "jidhnyasa03/devops-site"
    S3_BUCKET    = "jidhnyasa-devops-site-2025"
    AWS_REGION   = "ap-south-1"
  }

  stages {

    stage("Checkout") {
      steps {
        git branch: "main", url: "https://github.com/Jidhnyasa03/devops-static-site.git"
      }
    }

    stage("Docker Build") {
      steps {
        sh "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ."
        sh "docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest"
      }
    }

    stage("Docker Push") {
      steps {
        withCredentials([usernamePassword(credentialsId:"dockerhub-creds",usernameVariable:"DU",passwordVariable:"DP")]) {
          sh "echo $DP | docker login -u $DU --password-stdin"
          sh "docker push ${DOCKER_IMAGE}:latest"
        }
      }
    }

    stage("Deploy to S3") {
      steps {
        withCredentials([[$class:"AmazonWebServicesCredentialsBinding",credentialsId:"aws-creds"]]) {
          sh "aws s3 sync ./website/ s3://${S3_BUCKET} --delete --region ${AWS_REGION}"
        }
      }
    }

  }

  post {
    success {
      withCredentials([string(credentialsId:"slack-webhook",variable:"SLACK_URL")]) {
        sh """
          curl -X POST -H 'Content-type: application/json' \
          --data '{"text":"✅ Build #${BUILD_NUMBER} SUCCESS — devops-site deployed to S3!\\nJob: ${JOB_NAME}\\nURL: ${BUILD_URL}"}' \
          $SLACK_URL
        """
      }
      echo "Site deployed successfully!"
    }
    failure {
      withCredentials([string(credentialsId:"slack-webhook",variable:"SLACK_URL")]) {
        sh """
          curl -X POST -H 'Content-type: application/json' \
          --data '{"text":"❌ Build #${BUILD_NUMBER} FAILED — devops-site pipeline failed!\\nJob: ${JOB_NAME}\\nURL: ${BUILD_URL}"}' \
          $SLACK_URL
        """
      }
      echo "Build failed — check Console Output"
    }
  }
}