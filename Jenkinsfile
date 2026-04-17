@Library('cicd-library') _

pipeline {
    agent any

    triggers {
        githubPush()
    }

    parameters {
        string(name: 'BRANCH', defaultValue: '', description: 'Branch (optional)')
        choice(name: 'REQUIRED', choices: ['Build', 'Deploy'], description: 'Action')
    }

    environment {
        PARAMS_FILE = "${env.WORKSPACE}/build-params.env"
    }

    stages {

        // ✅ ALWAYS checkout first
        stage('Checkout') {
            steps {
                script {
                    def branchToBuild = params.BRANCH ?: (env.GIT_BRANCH?.replaceAll('origin/', '') ?: 'UAT')

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

        // ✅ Proper merge filtering
        stage('Check Merge Commit') {
            steps {
                script {
                    def commitMsg = sh(
                        script: "git log -1 --pretty=%B",
                        returnStdout: true
                    ).trim()

                    echo "📝 Commit Message: ${commitMsg}"

                    if (!commitMsg.contains("Merge pull request")) {
                        echo "⛔ Not a merge commit → skipping pipeline"
                        currentBuild.result = 'NOT_BUILT'
                        error("Stopping pipeline (not a merge commit)")
                    }

                    echo "✅ Merge commit detected"
                }
            }
        }

        stage('Detect PR & ENV') {
            steps {
                script {
                    // Commit hash
                    env.COMMIT_HASH = sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()

                    // Commit message
                    def commitMsg = sh(
                        script: "git log -1 --pretty=%B",
                        returnStdout: true
                    ).trim()

                    // Extract PR number
                    def matcher = commitMsg =~ /#(\\d+)/
                    def prNumber = matcher ? matcher[0][1] : null

                    if (!prNumber) {
                        error "❌ Could not extract PR number from merge commit"
                    }

                    echo "🔎 PR #: ${prNumber}"

                    // Repo info
                    def gitUrl = sh(
                        script: "git config --get remote.origin.url",
                        returnStdout: true
                    ).trim()

                    def repo = gitUrl.tokenize('/').takeRight(2).join('/').replace('.git','')

                    // GitHub API
                    def apiUrl = "https://api.github.com/repos/${repo}/issues/${prNumber}"

                    def response = sh(
                        script: "curl -s ${apiUrl}",
                        returnStdout: true
                    ).trim()

                    def json = readJSON text: response

                    def labels = json.labels.collect { it.name.toLowerCase() }
                    def body   = (json.body ?: "").toLowerCase()

                    echo "🏷️ Labels: ${labels}"
                    echo "📄 Description: ${body}"

                    // Resolve env
                    def resolvedEnv = null

                    if (labels.contains('uat')) {
                        resolvedEnv = 'uat'
                    } else if (labels.contains('stage')) {
                        resolvedEnv = 'stage'
                    } else if (labels.contains('prod')) {
                        resolvedEnv = 'prod'
                    } else if (body.contains('uat')) {
                        resolvedEnv = 'uat'
                    } else if (body.contains('stage')) {
                        resolvedEnv = 'stage'
                    } else if (body.contains('prod')) {
                        resolvedEnv = 'prod'
                    } else {
                        error "❌ No BUILD_ENV found"
                    }

                    env.BUILD_ENV = resolvedEnv
                    env.REQUIRED  = params.REQUIRED

                    echo """
===============================
JOB_NAME    : ${env.JOB_NAME}
BRANCH      : ${env.BRANCH}
COMMIT_HASH : ${env.COMMIT_HASH}
BUILD_ENV   : ${env.BUILD_ENV}
REQUIRED    : ${env.REQUIRED}
WORKSPACE   : ${env.WORKSPACE}
===============================
"""
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










// @Library('cicd-library') _

// pipeline {
//     agent any

//     triggers {
//         githubPush()
//     }

//     parameters {
//         string(name: 'BRANCH', defaultValue: '', description: 'Git branch')
//         string(name: 'PR_NUMBER', defaultValue: '', description: 'Pull Request Number')
//         choice(name: 'BUILD_ENV', choices: ['stage', 'uat', 'prod'], description: 'Environment (fallback)')
//         choice(name: 'REQUIRED', choices: ['Build', 'Deploy'], description: 'Action')
//     }

//     environment {
//         PARAMS_FILE = "${env.WORKSPACE}/build-params.env"
//     }

//     stages {

//         stage('Checkout') {
//             steps {
//                 script {
//                     def branchToBuild = params.BRANCH ?: 'master'

//                     echo "📥 Checking out branch: ${branchToBuild}"

//                     checkout([
//                         $class: 'GitSCM',
//                         branches: [[name: "*/${branchToBuild}"]],
//                         userRemoteConfigs: [[url: scm.userRemoteConfigs[0].url]]
//                     ])

//                     env.BRANCH = branchToBuild
//                 }
//             }
//         }

//         stage('Validate Input') {
//             steps {
//                 script {
//                     echo "DEBUG → PR_NUMBER raw = '${params.PR_NUMBER}'"

//                     if (!params.BRANCH) {
//                         error "❌ Missing BRANCH"
//                     }

//                     if (!params.PR_NUMBER?.trim() && !params.BUILD_ENV) {
//                         error "❌ Either PR_NUMBER or BUILD_ENV must be provided"
//                     }

//                     echo "🚀 Branch: ${params.BRANCH}"
//                     echo "⚙️ Action: ${params.REQUIRED}"
//                 }
//             }
//         }

//         stage('Prepare Params') {
//             steps {
//                 script {

//                     // Basic values
//                     env.COMMIT_HASH = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
//                     env.REQUIRED    = params.REQUIRED

//                     def resolvedEnv = params.BUILD_ENV

//                     // If PR_NUMBER is provided → fetch labels
//                     if (params.PR_NUMBER?.trim()) {

//                         echo "🔎 Fetching labels for PR #${params.PR_NUMBER}"

//                         // Get repo dynamically
//                         def gitUrl = sh(
//                             script: "git config --get remote.origin.url",
//                             returnStdout: true
//                         ).trim()

//                         def repo = gitUrl.tokenize('/').takeRight(2).join('/').replace('.git','')

//                         def apiUrl = "https://api.github.com/repos/${repo}/issues/${params.PR_NUMBER}"

//                         def response = sh(
//                             script: "curl -s ${apiUrl}",
//                             returnStdout: true
//                         ).trim()

//                         echo "DEBUG → API Response: ${response}"

//                         def json = readJSON text: response

//                         def labels = json.labels.collect { it.name.toLowerCase() }

//                         echo "🏷️ PR Labels: ${labels}"

//                         // Decide BUILD_ENV
//                         if (labels.contains('uat')) {
//                             resolvedEnv = 'uat'
//                         } else if (labels.contains('stage')) {
//                             resolvedEnv = 'stage'
//                         } else if (labels.contains('prod')) {
//                             resolvedEnv = 'prod'
//                         } else {
//                             error "❌ No valid env label (uat/stage/prod) found on PR"
//                         }

//                     } else {
//                         echo "ℹ️ No PR_NUMBER → using BUILD_ENV parameter"
//                     }

//                     env.BUILD_ENV = resolvedEnv

//                     echo """
// ===============================
// JOB_NAME    : ${env.JOB_NAME}
// BRANCH      : ${env.BRANCH}
// COMMIT_HASH : ${env.COMMIT_HASH}
// BUILD_ENV   : ${env.BUILD_ENV}
// REQUIRED    : ${env.REQUIRED}
// WORKSPACE   : ${env.WORKSPACE}
// ===============================
// """
//                 }

//                 writeFile file: env.PARAMS_FILE, text: """\
// JOB_NAME=${env.JOB_NAME}
// BRANCH=${env.BRANCH}
// COMMIT_HASH=${env.COMMIT_HASH}
// BUILD_ENV=${env.BUILD_ENV}
// REQUIRED=${env.REQUIRED}
// WORKSPACE=${env.WORKSPACE}
// """
//             }
//         }

//         stage('Run Deployment') {
//             steps {
//                 deploy("${env.PARAMS_FILE}")
//             }
//         }
//     }
// }














// @Library('cicd-library') _

// pipeline {
//     agent any

//     triggers {
//         githubPush()
//     }

//     parameters {
//         string(name: 'BRANCH', defaultValue: '', description: 'Git branch')
//         string(name: 'PR_NUMBER', defaultValue: '', description: 'Pull Request Number')
//         choice(name: 'BUILD_ENV', choices: ['uat', 'stage', 'prod'], description: 'Environment')
//         choice(name: 'REQUIRED', choices: ['Build', 'Deploy'], description: 'Action')
//     }

//     environment {
//         PARAMS_FILE = "${env.WORKSPACE}/build-params.env"
//     }

//     stages  {

//         stage('Checkout') {
//             steps {
//                 script {
                        
//                     def branchToBuild = params.BRANCH ?: 'master'

//                     checkout([
//                         $class: 'GitSCM',
//                         branches: [[name: "*/${branchToBuild}"]],
//                         userRemoteConfigs: [[url: env.GIT_URL]]
//                     ])

//                     env.BRANCH = branchToBuild
//                     }
//                 }
//             }

//         stage('Validate Input') {
//             steps {
//                 script {
//                     if (!params.BRANCH || !params.BUILD_ENV) {
//                         error "❌ Missing BRANCH or BUILD_ENV"
//                     }

//                     echo "🚀 Branch: ${params.BRANCH}"
//                     echo "🌍 Env: ${params.BUILD_ENV}"
//                     echo "⚙️ Action: ${params.REQUIRED}"
//                 }
//             }
//         }

//         stage('Prepare Params') {
//             steps {
//                 script {
//                     // Basic values
//                     env.BRANCH      = params.BRANCH ?: env.GIT_BRANCH?.replaceAll('origin/', '')
//                     env.COMMIT_HASH = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
//                     env.REQUIRED    = params.REQUIRED

//                     // Default fallback
//                     def resolvedEnv = params.BUILD_ENV

//                     // If PR_NUMBER is provided → fetch labels
//                     if (params.PR_NUMBER?.trim()) {
//                         echo "Fetching labels for PR #${params.PR_NUMBER}"
//                         echo "DEBUG → PR_NUMBER = '${params.PR_NUMBER}'"

//                         def gitUrl = env.GIT_URL
//                         def repo = gitUrl.tokenize('/').takeRight(2).join('/').replace('.git','')
//                         def apiUrl = "https://api.github.com/repos/${repo}/issues/${params.PR_NUMBER}"

//                         def response = sh(
//                             script: """curl -s ${apiUrl}""",
//                             returnStdout: true
//                         ).trim()
//                         echo "DEBUG → API Response = ${response}"
//                         def json = readJSON text: response

//                         def labels = json.labels.collect { it.name.toLowerCase() }
//                         echo "PR Labels: ${labels}"

//                         // Decide BUILD_ENV from labels
//                         if (labels.contains('uat')) {
//                             resolvedEnv = 'uat'
//                         } else if (labels.contains('stage')) {
//                             resolvedEnv = 'stage'
//                         } else if (labels.contains('prod')) {
//                             resolvedEnv = 'prod'
//                         } else {
//                             error "❌ No valid env label (uat/stage/prod) found on PR"
//                         }
//                     } else {
//                         echo "No PR_NUMBER provided, using parameter BUILD_ENV"
//                     }

//                     env.BUILD_ENV = resolvedEnv

//                     echo """
//         ===============================
//         JOB_NAME    : ${env.JOB_NAME}
//         BRANCH      : ${env.BRANCH}
//         COMMIT_HASH : ${env.COMMIT_HASH}
//         BUILD_ENV   : ${env.BUILD_ENV}
//         REQUIRED    : ${env.REQUIRED}
//         WORKSPACE   : ${env.WORKSPACE}
//         ===============================
//         """
//                 }
//                 writeFile file: env.PARAMS_FILE, text: """\
//         JOB_NAME=${env.JOB_NAME}
//         BRANCH=${env.BRANCH}
//         COMMIT_HASH=${env.COMMIT_HASH}
//         BUILD_ENV=${env.BUILD_ENV}
//         REQUIRED=${env.REQUIRED}
//         WORKSPACE=${env.WORKSPACE}
//         """
//             }
//         }

//         stage('Run Deployment') {
//             steps {
//                 deploy("${env.PARAMS_FILE}")   
//             }
//         }
//     }
// }
