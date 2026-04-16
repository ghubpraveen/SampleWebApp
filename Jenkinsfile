@Library('cicd-library') _

pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        PARAMS_FILE = "${env.WORKSPACE}/build-params.env"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare Params') {
            steps {
                script {
                    env.BRANCH       = env.GIT_BRANCH?.replaceAll('origin/', '') ?: 'master'
                    env.COMMIT_HASH  = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()

                    env.REQUIRED     = "Build"
                    env.BUILD_ENV    = "uat"
                }

                writeFile file: env.PARAMS_FILE, text: """\
JOB_NAME=${env.JOB_NAME}
BRANCH=${env.BRANCH}
COMMIT_HASH=${env.COMMIT_HASH}
BUILD_ENV=${env.BUILD_ENV}
REQUIRED=${env.REQUIRED}
WORKSPACE=${env.WORKSPACE}
"""
            }
        }

        stage('Run Deployment') {
            steps {
                deploy("${env.PARAMS_FILE}")   // ✅ THIS is correct usage
            }
        }
    }
}