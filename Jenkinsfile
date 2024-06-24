pipeline {
    agent {
    docker {
      image 'abhishekf5/maven-abhishek-docker-agent:v1'
      args '--user root -v /var/run/docker.sock:/var/run/docker.sock' // mount Docker socket to access the host's Docker daemon
    }
  }
    
    tools {
        jdk 'jdk17'
        maven 'maven3'
    }

    environment {
        SCANNER_HOME= tool 'sonar-scanner'
    }

    stages {
        stage('Git Checkout') {
            steps {
               git branch: 'main', credentialsId: 'git-cred', url: ##your github repo
            }
        }
        
        stage('Compile') {
            steps {
                sh "mvn compile"
            }
        }
        
        stage('Test') {
            steps {
                sh "mvn test"
            }
        }
        
        stage('File System Scan') {
            steps {
                sh "trivy fs --format table -o trivy-fs-report.html ."
            }
        }
        
        stage('SonarQube Analsyis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=BoardGame -Dsonar.projectKey=BoardGame \
                            -Dsonar.java.binaries=. '''
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                  waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token' 
                }
            }
        }
        
        stage('Build') {
            steps {
               sh "mvn package"
            }
        }
        
        stage('Publish To Nexus') {
            steps {
               withMaven(globalMavenSettingsConfig: 'global-settings', jdk: 'jdk17', maven: 'maven3', mavenSettingsConfig: '', traceability: true) {
                    sh "mvn deploy"
                }
            }
        }
        
        stage('Build & Tag Docker Image') {
			environment {
				DOCKER_IMAGE = "nirmal8717/boardshack:${BUILD_NUMBER}"
				REGISTRY_CREDENTIALS = credentials('docker-cred')
			}
			steps {
				script {
					sh 'docker build -t ${DOCKER_IMAGE} .'
					def dockerImage = docker.image("${DOCKER_IMAGE}")
			    }
            }
        }
        
        stage('Docker Image Scan') {
            steps {
                sh "trivy image --format table -o trivy-image-report.html  ##your docker image"
            }
        }
        
        stage('Push Docker Image') {
			environment {
				DOCKER_IMAGE = "nirmal8717/boardshack:${BUILD_NUMBER}"
				REGISTRY_CREDENTIALS = credentials('docker-cred')
			}
            steps {
               script {
                   docker.withRegistry('https://index.docker.io/v1/', "docker-cred") {
						dockerImage.push()
                    }
                }
            }
        }
		
		stage('Update Deployment File') {
			environment {
				GIT_REPO_NAME = "Boardgame"
				GIT_USER_NAME = "DevopsLearn8717"
			}
			steps {
				withCredentials([string(credentialsId: 'github', variable: 'GITHUB_TOKEN')]) {
					sh '''
                    git config user.email "devopsLearn8717@gmail.com"
                    git config user.name "DevopsLearn8717"
                    BUILD_NUMBER=${BUILD_NUMBER}
                    sed -i "s/replaceImageTag/${BUILD_NUMBER}/g" deployment-service.yaml
                    git add deployment-service.yaml
                    git commit -m "Update deployment image to version ${BUILD_NUMBER}"
                    git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main
					'''
				}
			}
		}		      
    }
    post {
    always {
        script {
            def jobName = env.JOB_NAME
            def buildNumber = env.BUILD_NUMBER
            def pipelineStatus = currentBuild.result ?: 'UNKNOWN'
            def bannerColor = pipelineStatus.toUpperCase() == 'SUCCESS' ? 'green' : 'red'

            def body = """
                <html>
                <body>
                <div style="border: 4px solid ${bannerColor}; padding: 10px;">
                <h2>${jobName} - Build ${buildNumber}</h2>
                <div style="background-color: ${bannerColor}; padding: 10px;">
                <h3 style="color: white;">Pipeline Status: ${pipelineStatus.toUpperCase()}</h3>
                </div>
                <p>Check the <a href="${BUILD_URL}">console output</a>.</p>
                </div>
                </body>
                </html>
            """

            emailext (
                subject: "${jobName} - Build ${buildNumber} - ${pipelineStatus.toUpperCase()}",
                body: body,
                to: 'devops.learn8717@gmail.com',
                from: 'jenkins@example.com',
                replyTo: 'jenkins@example.com',
                mimeType: 'text/html',
                attachmentsPattern: 'trivy-image-report.html'
            )
        }
    }
}

}