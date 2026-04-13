pipeline {
    agent any

    
    environment {
        PARAMS_FILE = "${env.WORKSPACE}/build-params.env"
        DEPLOY_SCRIPT = "${WORKSPACE}/deploy.sh"
        
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

        stage('3. Sample sh') {
            steps {
                script {
                    println "Before sh step"

                    try {
                        sh '''
                            echo "Inside shell"
                            whoami
                            pwd
                        '''    
                    } catch (e) {
                        println "Shell failed: $(e)"
                    }
                    println "After sh step"
                }
            }
        }

    post{
        success {
            echo "🎉 Build SUCCESS - Branch : ${env.Branch} | Commit: ${env.COMMIT_HASH}"
        }
        failure {
            echo "❌ Build FAILED - Check console output above"
        }
    }
   
}

