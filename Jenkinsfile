pipeline {
    agent any

    triggers {
        pollSCM('* * * * *')
    }

    environment {
        PARAMS_FILE = "${env.WORKSPACE}/build-params.env"
    }

    stages {

        stage('0. Checkout') {
            steps {
                checkout scm
            }
        }

        stage('1. Extract Parameters') {
            steps {
                script {
                    env.BRANCH      = env.GIT_BRANCH.replaceAll('origin/', '')
                    env.COMMIT_HASH = env.GIT_COMMIT
                    env.BUILD_CAUSE = 'jenkins-bot'
                    env.REQUIRED    = 'Build'
                    env.BUILD_ENV   = 'uat'

                    echo "BRANCH      : ${env.BRANCH}"
                    echo "COMMIT_HASH : ${env.COMMIT_HASH}"
                    echo "BUILD_CAUSE : ${env.BUILD_CAUSE}"
                    echo "REQUIRED    : ${env.REQUIRED}"
                    echo "BUILD_ENV   : ${env.BUILD_ENV}"
                }
            }
        }

        stage('2. Write Params to File') {
            steps {
                script {
                    writeFile file: env.PARAMS_FILE, text: "JOB_NAME=${env.JOB_NAME}\nBRANCH=${env.BRANCH}\nCOMMIT_HASH=${env.COMMIT_HASH}\nBUILD_ENV=${env.BUILD_ENV}\nREQUIRED=${env.REQUIRED}\nBUILD_CAUSE=${env.BUILD_CAUSE}\nWORKSPACE=${env.WORKSPACE}\n"
                    echo "Params written:"
                    echo readFile(env.PARAMS_FILE)
                }
            }
        }

        stage('3. Build WAR') {
            steps {
                sh '#!/bin/sh -e\ncd ${WORKSPACE} && mvn clean package -DskipTests'
            }
        }

        stage('4. Archive WAR') {
            steps {
                archiveArtifacts artifacts: 'target/*.war', fingerprint: true
            }
        }
    }

    post {
        success {
            echo "SUCCESS"
        }
        failure {
            echo "FAILED"
        }
    }
}