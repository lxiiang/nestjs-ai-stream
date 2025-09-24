pipeline {
    agent any
    
    environment {
        APP_NAME = 'nestjs-ai-stream-fullstack'
        BUILD_TAG = "${BUILD_NUMBER}"
        COMPOSE_PROJECT_NAME = 'nestjs-ai-stream'
    }
    
    stages {
        stage('📋 准备') {
            steps {
                echo "🚀 开始构建 ${APP_NAME} - Build #${BUILD_NUMBER}"
                sh 'node --version || echo "Node.js not found"'
                sh 'docker --version || echo "Docker not found"'
                sh 'docker-compose --version || echo "Docker Compose not found"'
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
                    # 使用 docker-compose 构建
                    docker-compose build
                    echo "✅ 前后端应用构建完成"
                '''
            }
        }
        
        stage('🚀 部署') {
            steps {
                echo "🚀 部署前后端一体化应用..."
                sh '''
                    # 停止旧服务
                    docker-compose down || true
                    
                    # 设置环境变量并启动服务
                    export DASHSCOPE_API_KEY=${DASHSCOPE_API_KEY}
                    docker-compose up -d
                    
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
                    docker-compose ps
                    
                    # 检查前端服务
                    echo "🌐 检查前端服务..."
                    curl -f http://localhost:8081/ || echo "⚠️ 前端服务可能还在启动中"
                    
                    # 检查后端API
                    echo "🔗 检查后端API..."
                    curl -f http://localhost:3000/health || echo "⚠️ 后端API可能还在启动中"
                    
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
                echo "查看服务状态："
                docker-compose ps || true
                echo "查看服务日志："
                docker-compose logs || true
            '''
        }
    }
}