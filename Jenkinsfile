@Library('cicd-library') _
pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        PARAMS_FILE = "${env.WORKSPACE}/build-params.env"
    }

#    tools {
#    maven 'Maven-3.9.14'   // must match Jenkins tool name EXACTLY
#}

    stages {

        stage('1. Extract Parameters') {
            steps {
                script {
                    env.BRANCH       = env.GIT_BRANCH?.replaceAll('origin/', '') ?: 'master'
                    env.COMMIT_HASH  = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                    env.BUILD_CAUSE  = 'jenkins-bot'
                    env.REQUIRED     = 'Build'
                    env.BUILD_ENV    = 'uat'

                    echo """
======= Parameters =======
BRANCH      : ${env.BRANCH}
COMMIT_HASH : ${env.COMMIT_HASH}
BUILD_ENV   : ${env.BUILD_ENV}
==========================
"""
                }
            }
        }

        stage('2. Create Params File') {
            steps {
                writeFile file: env.PARAMS_FILE, text: """\
JOB_NAME=${env.JOB_NAME}
BRANCH=${env.BRANCH}
COMMIT_HASH=${env.COMMIT_HASH}
BUILD_ENV=${env.BUILD_ENV}
REQUIRED=${env.REQUIRED}
BUILD_CAUSE=${env.BUILD_CAUSE}
WORKSPACE=${env.WORKSPACE}
"""
                sh "cat ${env.PARAMS_FILE}"
            }
        }

        stage('3. Build WAR') {
            steps {


                script {
                    #def mvnHome = tool '3.9.14'
                    #sh """
                    #export PATH=${mvnHome}/bin:\$PATH
                    #echo "Using Maven from: ${mvnHome}"
                    #mvn -v

                    echo "📦 Running deployment script..."
                    bash ${env.WORKSPACE}/deploy.sh ${env.PARAMS_FILE}
                """
                }
            }
        }

        stage('4. Archive WAR') {
            steps {
                archiveArtifacts artifacts: 'target/*.war', fingerprint: true
                echo "✅ WAR archived"
            }
        }
    }

    post {
        success {
            echo "🎉 SUCCESS"
        }
        failure {
            echo "❌ FAILED"
        }
    }
}




// pipeline {
//     agent any

//     triggers {
//         githubPush()
//     }

//     environment {
//         PARAMS_FILE = "/tmp/jenkins-params/${env.JOB_NAME}-build-params.env"
//         BUILD_ENV   = "uat"
//         REQUIRED    = "Build"
//         BUILD_CAUSE = "jenkins-bot"
//     }

//     stages {

//         stage('1. Extract Parameters') {
//             steps {
//                 script {
//                     // safer branch detection
//                     env.BRANCH = sh(
//                         script: "git rev-parse --abbrev-ref HEAD",
//                         returnStdout: true
//                     ).trim()

//                     env.COMMIT_HASH = sh(
//                         script: "git rev-parse HEAD",
//                         returnStdout: true
//                     ).trim()

//                     echo """
//                     ======= Parameters Extracted =======
//                     BRANCH      : ${env.BRANCH}
//                     COMMIT_HASH : ${env.COMMIT_HASH}
//                     BUILD_CAUSE : ${env.BUILD_CAUSE}
//                     REQUIRED    : ${env.REQUIRED}
//                     BUILD_ENV   : ${env.BUILD_ENV}
//                     ====================================
//                     """
//                 }
//             }
//         }

//         stage('2. Write Params File') {
//             steps {
//                 script {
//                     sh """
//                         mkdir -p \$(dirname ${PARAMS_FILE})
//                     """

//                     writeFile file: PARAMS_FILE, text: """\
// JOB_NAME=${env.JOB_NAME}
// BRANCH=${env.BRANCH}
// COMMIT_HASH=${env.COMMIT_HASH}
// BUILD_ENV=${env.BUILD_ENV}
// REQUIRED=${env.REQUIRED}
// BUILD_CAUSE=${env.BUILD_CAUSE}
// WORKSPACE=${env.WORKSPACE}
// """

//                     echo "📄 Params written to: ${PARAMS_FILE}"
//                     sh "cat ${PARAMS_FILE}"
//                 }
//             }
//         }

//         stage('3. Execute deploy.sh') {
//             steps {
//                 sh """
//                     set -e
//                     set -x

//                     echo "🚀 Running deploy.sh..."

//                     chmod +x ${WORKSPACE}/deploy.sh
//                     ${WORKSPACE}/deploy.sh ${PARAMS_FILE}
//                 """
//             }
//         }

//         stage('4. Archive WAR') {
//             steps {
//                 archiveArtifacts artifacts: '**/*.war', fingerprint: true
//                 echo "✅ WAR archived successfully"
//             }
//         }
//     }

//     post {
//         success {
//             echo "🎉 SUCCESS — ${env.BRANCH} @ ${env.COMMIT_HASH}"
//         }
//         failure {
//             echo "❌ FAILED — Check logs"
//         }
//     }
// }
