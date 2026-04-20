@Library('cicd-library') _

pipeline {
    agent any

    environment {
        PARAMS_FILE = "${env.WORKSPACE}/build-params.env"
    }

    stages {

        // ✅ Always checkout the branch that triggered build
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

        // ✅ Allow ONLY merge commits
        stage('Check Merge Commit') {
            steps {
                script {
                    def commitMsg = sh(
                        script: "git log -1 --pretty=%B",
                        returnStdout: true
                    ).trim()

                    echo "📝 Commit Message:\n${commitMsg}"

                    if (!(commitMsg =~ /(?i)merge pull request|#\d+/)) {
                        error "⛔ Not a PR merge commit. Skipping pipeline."
                    }

                    echo "✅ Merge commit detected"
                }
            }
        }

        // ✅ Detect PR + ENV dynamically
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

                    // Extract PR number (works for merge & squash)
                    def matcher = (commitMsg =~ /#(\d+)/)
                    def prNumber = matcher.find() ? matcher.group(1) : null

                    echo "🔎 PR #: ${prNumber}"

                    // Extract repo dynamically
                    def gitUrl = sh(
                        script: "git config --get remote.origin.url",
                        returnStdout: true
                    ).trim()

                    def repo = gitUrl.tokenize('/').takeRight(2).join('/').replace('.git','')

                    def resolvedEnv = null

                    // ✅ Try PR labels (if PR exists)
                    if (prNumber) {
                        def apiUrl = "https://api.github.com/repos/${repo}/issues/${prNumber}"

                        def response = sh(
                            script: "curl -s ${apiUrl}",
                            returnStdout: true
                        ).trim()

                        def json = readJSON text: response

                        def labels = json.labels.collect { it.name.toLowerCase() }

                        echo "🏷️ Labels: ${labels}"

                        if (labels.contains('uat')) {
                            resolvedEnv = 'uat'
                        } else if (labels.contains('stage')) {
                            resolvedEnv = 'stage'
                        } else if (labels.contains('prod')) {
                            resolvedEnv = 'prod'
                        }
                    }

                    // ✅ Fallback → commit message
                    if (!resolvedEnv) {
                        def envMatcher = (commitMsg =~ /(?i)BUILD_ENV\s*=\s*(\w+)/)
                        resolvedEnv = envMatcher.find() ? envMatcher.group(1).toLowerCase() : null

                        echo "📄 ENV from commit message: ${resolvedEnv}"
                    }

                    if (!resolvedEnv) {
                        error "❌ BUILD_ENV not found in PR labels or commit message"
                    }

                    env.BUILD_ENV = resolvedEnv
                    env.REQUIRED  = "Build"   // default action

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

                writeFile file: env.PARAMS_FILE, text: """\
JOB_NAME=${env.JOB_NAME}
BRANCH=${env.BRANCH}
COMMIT_HASH=${env.COMMIT_HASH}
BUILD_ENV=${env.BUILD_ENV}
WORKSPACE=${env.WORKSPACE}
"""
            }
        }

        // ✅ Final execution
        stage('Run Deployment') {
            steps {
                deploy("${env.PARAMS_FILE}")
            }
        }
    }
}