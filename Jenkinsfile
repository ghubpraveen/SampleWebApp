@Library('cicd-library') _

pipeline {
    agent any

    triggers {
        githubPush()
    }

    parameters {
        string(name: 'BRANCH', defaultValue: '', description: 'Git branch')
        choice(name: 'BUILD_ENV', choices: ['uat', 'stage', 'prod'], description: 'Environment')
        choice(name: 'REQUIRED', choices: ['Build', 'Deploy'], description: 'Action')
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

        stage('Validate Input') {
            steps {
                script {
                    if (!params.BRANCH || !params.BUILD_ENV) {
                        error "❌ Missing BRANCH or BUILD_ENV"
                    }

                    echo "🚀 Branch: ${params.BRANCH}"
                    echo "🌍 Env: ${params.BUILD_ENV}"
                    echo "⚙️ Action: ${params.REQUIRED}"
                }
            }
        }

        stage('Prepare Params') {
            steps {
                script {
                    env.BRANCH       = params.BRANCH ?: env.GIT_BRANCH?.replaceAll('origin/', '')
                    env.COMMIT_HASH  = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()

                    env.REQUIRED     = params.REQUIRED
                    env.BUILD_ENV    = params.BUILD_ENV
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
                deploy("${env.PARAMS_FILE}")   
            }
        }
    }
}
