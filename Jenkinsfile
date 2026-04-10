pipeline {
    agent any

    // triggers {
    //     pollSCM('* * * * *')
    // }
    
    triggers {
        githubPush()   // auto-triggers when code is pushed/merged
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

                    echo """
                    ======= Parameters Extracted =======
                    BRANCH      : ${env.BRANCH}
                    COMMIT_HASH : ${env.COMMIT_HASH}
                    BUILD_CAUSE : ${env.BUILD_CAUSE}
                    REQUIRED    : ${env.REQUIRED}
                    BUILD_ENV   : ${env.BUILD_ENV}
                    ====================================
                    """
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
                script {
                    sh "bash -x ${env.WORKSPACE}/deploy.sh ${env.PARAMS_FILE}"
                }
            }
        }
        stage('4. Archive WAR') {
            steps {
                // Save the WAR as a Jenkins build artifact
                archiveArtifacts artifacts: 'target/*.war', fingerprint: true
                echo "✅ WAR archived successfully"
            }
        }
    }

    post {
        success {
            echo "🎉 Build SUCCESS — Branch: ${env.BRANCH} | Commit: ${env.COMMIT_HASH}"
        }
        failure {
            echo "❌ Build FAILED — Check console output above"
        }
    }
}