#!/bin/bash
set -e

# QLDSV-HTC Service Management Script
# Usage: ./scripts/service-mgmt.sh {command} [service] [options]

# Load configuration
source scripts/utils/config-loader.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE} QLDSV-HTC Service Management${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_usage() {
    echo "Usage: $0 {command} [service] [options]"
    echo ""
    echo "Commands:"
    echo "  start [service]    - Start services"
    echo "  stop [service]     - Stop services"
    echo "  restart [service]  - Restart services"
    echo "  status            - Show services status"
    echo "  logs [service]    - Show service logs"
    echo "  setup             - Initial setup"
    echo "  cleanup           - Clean up containers and volumes"
    echo ""
    echo "Services:"
    echo "  all               - All services (default)"
    echo "  db, database      - Database only"
    echo "  backend, api      - Backend API only"
    echo "  frontend, ui      - Frontend only"
    echo ""
    echo "Examples:"
    echo "  $0 start all"
    echo "  $0 start db"
    echo "  $0 status"
    echo "  $0 logs db"
}

start_service() {
    local service=${1:-all}
    
    print_header
    echo -e "${GREEN}🚀 Starting QLDSV-HTC services...${NC}"
    
    case $service in
        "database"|"db")
            echo "Starting database service..."
            load_service_config database
            cd database && docker-compose up -d
            ;;
        "backend"|"api")
            echo "Starting backend service..."
            load_service_config backend
            cd backend && docker-compose up -d
            ;;
        "frontend"|"ui")
            echo "Starting frontend service..."
            load_service_config frontend
            cd frontend && docker-compose up -d
            ;;
        "all"|"")
            echo "Starting all services..."
            load_global_config
            docker-compose up -d
            ;;
        *)
            echo -e "${RED}❌ Unknown service: $service${NC}"
            print_usage
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}✅ Service(s) started successfully${NC}"
}

stop_service() {
    local service=${1:-all}
    
    print_header
    echo -e "${YELLOW}🛑 Stopping QLDSV-HTC services...${NC}"
    
    case $service in
        "database"|"db")
            cd database && docker-compose down
            ;;
        "backend"|"api")
            cd backend && docker-compose down
            ;;
        "frontend"|"ui")
            cd frontend && docker-compose down
            ;;
        "all"|"")
            docker-compose down
            ;;
        *)
            echo -e "${RED}❌ Unknown service: $service${NC}"
            print_usage
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}✅ Service(s) stopped successfully${NC}"
}

show_status() {
    print_header
    echo -e "${BLUE}📊 QLDSV-HTC Services Status${NC}"
    echo ""
    
    load_global_config
    
    # Show container status
    echo "🐳 Container Status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|qldsv-|$)"
    
    echo ""
    echo "🌐 Network Status:"
    if docker network ls | grep -q "$DOCKER_NETWORK"; then
        echo "✅ Network '$DOCKER_NETWORK' is active"
    else
        echo "❌ Network '$DOCKER_NETWORK' not found"
    fi
    
    echo ""
    echo "💾 Volume Status:"
    docker volume ls | grep -E "(DRIVER|qldsv|sqlserver)" || echo "No volumes found"
}

show_logs() {
    local service=${1:-all}
    
    case $service in
        "database"|"db")
            docker-compose logs -f database
            ;;
        "backend"|"api")
            docker-compose logs -f backend
            ;;
        "frontend"|"ui")
            docker-compose logs -f frontend
            ;;
        "all"|"")
            docker-compose logs -f
            ;;
        *)
            echo -e "${RED}❌ Unknown service: $service${NC}"
            exit 1
            ;;
    esac
}

setup_project() {
    print_header
    echo -e "${GREEN}🛠️ Running QLDSV-HTC initial setup...${NC}"
    
    # Run initial setup script
    if [ -f "scripts/setup/initial-setup.sh" ]; then
        ./scripts/setup/initial-setup.sh
    else
        echo -e "${RED}❌ Initial setup script not found${NC}"
        exit 1
    fi
}

cleanup_project() {
    print_header
    echo -e "${YELLOW}🧹 Cleaning up QLDSV-HTC resources...${NC}"
    
    read -p "⚠️  This will remove all containers, volumes, and networks. Continue? (yes/no): " confirm
    if [[ $confirm != "yes" ]]; then
        echo "Cleanup cancelled"
        exit 0
    fi
    
    load_global_config
    
    # Stop and remove containers
    docker-compose down -v --remove-orphans
    
    # Remove individual service containers
    for service_dir in database backend frontend; do
        if [ -d "$service_dir" ]; then
            cd "$service_dir"
            docker-compose down -v --remove-orphans 2>/dev/null || true
            cd ..
        fi
    done
    
    # Remove volumes
    docker volume rm $(docker volume ls -q | grep -E "(qldsv|sqlserver)") 2>/dev/null || true
    
    # Remove network
    docker network rm "$DOCKER_NETWORK" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Main script logic
case "${1:-help}" in
    "start")
        start_service "$2"
        ;;
    "stop")
        stop_service "$2"
        ;;
    "restart")
        stop_service "$2"
        sleep 2
        start_service "$2"
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs "$2"
        ;;
    "setup")
        setup_project
        ;;
    "cleanup")
        cleanup_project
        ;;
    "help"|"--help"|"-h")
        print_usage
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        print_usage
        exit 1
        ;;
esac