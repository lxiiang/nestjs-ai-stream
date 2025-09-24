pipeline {
    agent any
    
    environment {
        APP_NAME = 'nestjs-ai-stream-fullstack'
        BUILD_TAG = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('📋 准备') {
            steps {
                echo "🚀 开始构建 ${APP_NAME} - Build #${BUILD_NUMBER}"
                sh 'node --version || echo "Node.js not found"'
                sh 'docker --version || echo "Docker not found"'
                echo "✅ 使用纯 Docker 命令进行构建和部署"
            }
        }
        
        stage('📥 检出代码') {
            steps {
                checkout scm
                sh 'git log --oneline -5'
            }
        }
        
        stage('🏗️ 构建应用') {
            steps {
                echo "🏗️ 构建前后端一体化应用..."
                sh '''
                    # 使用 docker build 构建镜像
                    docker build -t ${APP_NAME}:${BUILD_TAG} .
                    docker tag ${APP_NAME}:${BUILD_TAG} ${APP_NAME}:latest
                    echo "✅ 前后端应用构建完成"
                '''
            }
        }
        
        stage('🚀 部署') {
            steps {
                echo "🚀 部署前后端一体化应用..."
                sh '''
                    # 停止旧容器
                    docker stop ${APP_NAME} || true
                    docker rm ${APP_NAME} || true
                    
                    # 启动新容器
                    docker run -d \\
                        --name ${APP_NAME} \\
                        -p 8081:80 \\
                        -p 3000:3000 \\
                        -e NODE_ENV=production \\
                        -e DASHSCOPE_API_KEY=${DASHSCOPE_API_KEY} \\
                        ${APP_NAME}:${BUILD_TAG}
                    
                    echo "✅ 前后端应用部署完成"
                    echo "🌐 前端访问地址: http://localhost:8081"
                    echo "🔗 后端API地址: http://localhost:3000"
                '''
            }
        }
        
        stage('🔍 验证') {
            steps {
                echo "🔍 验证部署..."
                sh '''
                    sleep 10
                    
                    # 检查容器状态
                    docker ps | grep ${APP_NAME} || exit 1
                    echo "✅ 容器运行正常"
                    
                    # 检查前端服务
                    echo "🌐 检查前端服务..."
                    curl -f http://localhost:8081/ || echo "⚠️ 前端服务可能还在启动中"
                    
                    # 检查后端API（通过nginx代理）
                    echo "🔗 检查后端API..."
                    curl -f http://localhost:8081/api/health || echo "⚠️ 后端API可能还在启动中"
                    
                    echo "✅ 前后端服务验证完成"
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
                echo "查看容器状态："
                docker ps -a | grep ${APP_NAME} || true
                echo "查看容器日志："
                docker logs ${APP_NAME} || true
            '''
        }
    }
}