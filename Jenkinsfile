pipeline {
    agent any
    
    environment {
        APP_NAME = 'nestjs-ai-stream'
        BUILD_TAG = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('📋 准备1') {
            steps {
                echo "🚀 开始构建 ${APP_NAME} - Build #${BUILD_NUMBER}"
                sh 'node --version || echo "Node.js not found"'
                sh 'docker --version || echo "Docker not found"'
            }
        }
        
        stage('📥 检出代码') {
            steps {
                checkout scm
                sh 'git log --oneline -5'
            }
        }
        
        stage('🏗️ 构建镜像') {
            steps {
                echo "🏗️ 构建 Docker 镜像..."
                sh '''
                    docker build -t ${APP_NAME}:${BUILD_TAG} .
                    docker tag ${APP_NAME}:${BUILD_TAG} ${APP_NAME}:latest
                    echo "✅ 镜像构建完成"
                '''
            }
        }
        
        stage('🚀 部署') {
            steps {
                echo "🚀 部署应用..."
                sh '''
                    # 停止旧容器
                    docker stop ${APP_NAME} || true
                    docker rm ${APP_NAME} || true
                    
                    # 启动新容器
                    docker run -d \\
                        --name ${APP_NAME} \\
                        -p 3000:3000 \\
                        -e NODE_ENV=production \\
                        -e DASHSCOPE_API_KEY=${DASHSCOPE_API_KEY} \\
                        ${APP_NAME}:${BUILD_TAG}
                    
                    echo "✅ 应用部署完成"
                '''
            }
        }
        
        stage('🔍 验证') {
            steps {
                echo "🔍 验证部署..."
                sh '''
                    sleep 5
                    docker ps | grep ${APP_NAME} || exit 1
                    echo "✅ 容器运行正常"
                    
                    # 简单的健康检查
                    curl -f http://localhost:3000/ || echo "⚠️ 服务可能还在启动中"
                '''
            }
        }
    }
    
    post {
        always {
            echo "🧹 清理..."
            sh '''
                # 清理旧镜像
                docker image prune -f || true
            '''
        }
        
        success {
            echo "✅ 构建部署成功！"
        }
        
        failure {
            echo "❌ 构建部署失败！"
            sh '''
                echo "查看容器日志："
                docker logs ${APP_NAME} || true
            '''
        }
    }
}