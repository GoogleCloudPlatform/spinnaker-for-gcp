@Library('cloudLibrary@3.0') _

def ops_timeout = 72
def build_if_changes_outside_these_patterns = ['**README.md', 'doc/**', 'postman/**', 'terraform-minikube/**', 'scripts/**']

pipeline {
    agent {
        kubernetes {
            label 'cicd-agent'
            defaultContainer 'agent'
        }
    }
    parameters {
        choice(choices: ['spg-zpc-sb', 'spg-zpc-d', 'spg-zpc-s', 'spg-zpc-p'], description: 'GCP project', name: 'gcp_project')
        string(defaultValue: 'us-central1-b', description: 'GCP location (zone/region)', name: 'gcp_location')
        string(defaultValue: 'spinnaker', description: 'Cluster name, derived if left as default, must match regexp "^(?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)$"', name: 'cluster_name')
        string(defaultValue: '2h', description: 'Cluster will be destroyed after this period of time', name: 'destroy_cluster_time')
        booleanParam(defaultValue: false, description: 'Manually input write SA', name: 'write_sa')
    }
    options {
        timestamps()
        ansiColor('xterm')
    }
    environment {
        READONLY_CREDS_FILE = "${env.HOME}/.gcp/${params.gcp_project}.json"
        CREDS_FILE = "admin_sa.json"
        ADMIN_CREDS_PATH = "${WORKSPACE}/${CREDS_FILE}"
        PARENT_DIR = "${WORKSPACE}"
        PROJECT_ID = "${params.gcp_project}"
    }
    stages {
        stage('Initialize Environment') {
            steps {
                script {
                    if (params.write_sa == true) {
                        env.GOOGLE_APPLICATION_CREDENTIALS = ADMIN_CREDS_PATH
                        deploy.getUserWriteSA()
                        deploy.askUserToDeleteKey(CREDS_FILE)
                    } else {
                        env.GOOGLE_APPLICATION_CREDENTIALS = READONLY_CREDS_FILE
                    }
                    currentBuild.displayName = "${params.cluster_name}-${currentBuild.number}"
                    echo "Cluster Name: ${currentBuild.displayName}"
                    echo "GOOGLE creds: ${GOOGLE_APPLICATION_CREDENTIALS}"
                    deploy.gcpAuth(GOOGLE_APPLICATION_CREDENTIALS)
                    sh "env | sort -u"
                }
            }
        }
        stage('Generate properties file') {
            steps {
                script {
                    sh "pwd"
                    sh "scripts/install/setup_properties.sh"
                    sh "cat properties"
                }
            }
        }
    }
    post {
        always {
            script {
                deploy.gcpAuth(READONLY_CREDS_FILE)
                if (fileExists(CREDS_FILE)) {
                    deploy.gcpRevoke(CREDS_FILE)
                    sh "rm -f ${CREDS_FILE}"
                }
            }
        }
        failure {
            script {
//                    deploy.sendEmailNotification('build_user', "JOB FAILED <br>NODE_LABELS: ${NODE_LABELS}<br>GIT_COMMIT: ${GIT_COMMIT}<br>Cluster name: ${env_params.cluster_name}")
                echo "Failed build"
            }
        }
    }
}