pipeline {
    agent any
    
    environment {
        // Docker 相关
        DOCKER_IMAGE = "nestjs-ai-stream:${BUILD_NUMBER}"
        DOCKER_LATEST = "nestjs-ai-stream:latest"
        
        // 应用配置
        APP_NAME = 'nestjs-ai-stream'
    }
    
    stages {
        stage('📋 环境准备') {
            steps {
                script {
                    echo "🚀 开始构建 ${APP_NAME}"
                    echo "📦 构建编号: ${BUILD_NUMBER}"
                    echo "🏷️  Docker 标签: ${DOCKER_IMAGE}"
                }
            }
        }
        
        stage('📥 代码检出') {
            steps {
                checkout scm
                
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    
                    echo "📝 Git 提交: ${env.GIT_COMMIT_SHORT}"
                }
            }
        }
        
        
        stage('🏗️ 构建镜像') {
            steps {
                script {
                    echo "🏗️ 构建 Docker 镜像..."
                    
                    // 构建镜像
                    def image = docker.build("${DOCKER_IMAGE}")
                    
                    // 打上 latest 标签
                    sh "docker tag ${DOCKER_IMAGE} ${DOCKER_LATEST}"
                    
                    echo "✅ 镜像构建完成: ${DOCKER_IMAGE}"
                }
            }
        }
        
        stage('🚀 部署应用') {
            steps {
                script {
                    echo "🚀 部署应用..."
                    
                    sh '''
                        # 停止旧容器
                        docker stop ${APP_NAME} || true
                        docker rm ${APP_NAME} || true
                        
                        # 启动新容器
                        docker run -d \
                            --name ${APP_NAME} \
                            -p 3000:3000 \
                            -e DASHSCOPE_API_KEY=${DASHSCOPE_API_KEY} \
                            ${DOCKER_IMAGE}
                        
                        echo "✅ 应用部署完成"
                    '''
                }
            }
        }
        
        stage('🔍 验证部署') {
            steps {
                script {
                    echo "🔍 验证部署状态..."
                    
                    sh '''
                        # 等待服务启动
                        sleep 10
                        
                        # 检查容器状态
                        docker ps | grep ${APP_NAME} || exit 1
                        echo "✅ 容器运行正常"
                        
                        # 简单的连接测试
                        curl -f http://localhost:3000/ || echo "⚠️ 服务连接测试失败，但容器正在运行"
                        
                        echo "🎉 部署验证完成"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo "🧹 清理工作空间..."
            
            // 清理旧镜像
            sh '''
                docker rmi ${DOCKER_IMAGE} || true
                docker system prune -f
            '''
        }
        
        success {
            echo "✅ 构建部署成功！"
        }
        
        failure {
            echo "❌ 构建部署失败！"
        }
    }
}