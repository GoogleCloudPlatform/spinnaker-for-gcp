@Library('cloudLibrary@3.0') _

pipeline {
    agent {
        kubernetes {
            label 'cicd-slim'
            defaultContainer 'agent'
        }
    }
    parameters {
        choice(choices: ['spg-zpc-tools', 'spg-zpc-sb', 'spg-zpc-d', 'spg-zpc-s', 'spg-zpc-p'], description: 'GCP project', name: 'gcp_project')
        string(defaultValue: 'us-central1-b', description: 'GCP location (zone/region)', name: 'gcp_location')
        string(defaultValue: 'spinnaker-4', description: 'Cluster name, derived if left as default, must match regexp "^(?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)$"', name: 'cluster_name')
        string(defaultValue: '2h', description: 'Cluster will be destroyed after this period of time', name: 'destroy_cluster_time')
        booleanParam(defaultValue: false, description: 'Enter write SA for dev/stage/prod', name: 'write_sa')
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
        ZONE = "us-central1-b"
        PROPERTIES_FILE = "scripts/install/properties"
        CI = "true" // CI=true was the same as CI = "true"
        TMPDIR = "${WORKSPACE}"
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
                    sh "gcloud config set project ${params.gcp_project}"
                    sh "env | sort -u"
                }
            }
        }
        stage('Generate properties file') {
            steps {
                script {
                    sh "pwd"
                    sh "scripts/install/setup_properties.sh"
                    sh "cat scripts/install/properties"
                }
            }
        }
        stage('deploy spinnaker') {
            steps {
                script {
                    sh "scripts/install/setup.sh"
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
