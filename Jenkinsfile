@Library('cicd-library') _

pipeline {
    agent any

    options {
        disableConcurrentBuilds()   // prevent parallel builds
    }

    environment {
        PARAMS_FILE = "${env.WORKSPACE}/build-params.env"
    }

    stages {

        // ✅ Checkout triggered branch
        stage('Checkout') {
            steps {
                script {
                    def branchToBuild = env.GIT_BRANCH?.replaceAll('origin/', '') ?: 'unknown'

                    echo "📥 Checking out branch: ${branchToBuild}"

                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "*/${branchToBuild}"]],
                        userRemoteConfigs: [[url: env.GIT_URL]]
                    ])

                    env.BRANCH = branchToBuild
                }
            }
        }

        // ✅ Allow only merge commits
        stage('Check Merge Commit') {
            steps {
                script {
                    def commitMsg = sh(
                        script: "git log -1 --pretty=%B",
                        returnStdout: true
                    ).trim()

                    echo "📝 Commit Message:\n${commitMsg}"

                    if (!commitMsg.toLowerCase().contains("merge pull request")) {
                        error "⛔ Not a merge commit. Skipping build."
                    }

                    echo "✅ Merge commit detected"
                }
            }
        }

        // ✅ Extract PR + BUILD_ENV
        stage('Detect PR & ENV') {
            steps {
                script {

                    // Commit info
                    env.COMMIT_HASH = sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()

                    def commitMsg = sh(
                        script: "git log -1 --pretty=%B",
                        returnStdout: true
                    ).trim()

                    // ✅ Extract PR number safely (NO matcher object stored)
                    def prNumber = null
                    def prMatch = (commitMsg =~ /#(\d+)/)
                    if (prMatch.find()) {
                        prNumber = prMatch.group(1)
                    }

                    echo "🔎 PR #: ${prNumber ?: 'Not Found'}"

                    // ✅ Extract BUILD_ENV from commit message
                    def buildEnv = null
                    def envMatch = (commitMsg =~ /(?i)BUILD_ENV\s*=\s*(\w+)/)
                    if (envMatch.find()) {
                        buildEnv = envMatch.group(1).toLowerCase()
                    }

                    echo "📄 ENV from commit message: ${buildEnv ?: 'Not Found'}"

                    // ✅ If not found → fallback to PR labels
                    if (!buildEnv && prNumber) {

                        def gitUrl = sh(
                            script: "git config --get remote.origin.url",
                            returnStdout: true
                        ).trim()

                        def repo = gitUrl.tokenize('/').takeRight(2).join('/').replace('.git','')

                        def apiUrl = "https://api.github.com/repos/${repo}/issues/${prNumber}"

                        def response = sh(
                            script: "curl -s ${apiUrl}",
                            returnStdout: true
                        ).trim()

                        def json = readJSON text: response

                        def labels = json.labels.collect { it.name.toLowerCase() }

                        echo "🏷️ Labels: ${labels}"

                        if (labels.contains('uat')) {
                            buildEnv = 'uat'
                        } else if (labels.contains('stage')) {
                            buildEnv = 'stage'
                        } else if (labels.contains('prod')) {
                            buildEnv = 'prod'
                        }
                    }

                    // ❌ Fail if still not found
                    if (!buildEnv) {
                        error "❌ BUILD_ENV not found in commit message or PR labels"
                    }

                    env.BUILD_ENV = buildEnv
                    env.REQUIRED  = "Build"   // default behavior

                    echo """
===============================
JOB_NAME    : ${env.JOB_NAME}
BRANCH      : ${env.BRANCH}
COMMIT_HASH : ${env.COMMIT_HASH}
BUILD_ENV   : ${env.BUILD_ENV}
WORKSPACE   : ${env.WORKSPACE}
===============================
"""
                }

                // ✅ Persist for shared library
                writeFile file: env.PARAMS_FILE, text: """\
JOB_NAME=${env.JOB_NAME}
BRANCH=${env.BRANCH}
COMMIT_HASH=${env.COMMIT_HASH}
BUILD_ENV=${env.BUILD_ENV}
WORKSPACE=${env.WORKSPACE}
"""
            }
        }

        // ✅ Execute shared library deployment
        stage('Run Deployment') {
            steps {
                deploy("${env.PARAMS_FILE}")
            }
        }
    }
}