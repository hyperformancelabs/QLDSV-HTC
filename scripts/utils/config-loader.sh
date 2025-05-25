#!/bin/bash

# Configuration loader with inheritance support
load_global_config() {
    echo "📂 Loading QLDSV-HTC configuration..."
    
    # Load global config first
    if [ -f ".env" ]; then
        echo "📄 Loading global config from .env"
        set -a
        source .env
        set +a
    else
        echo "❌ Global .env file not found!"
        exit 1
    fi
    
    # Load local overrides if available
    if [ -f ".env.local" ]; then
        echo "📄 Loading local overrides from .env.local"
        set -a
        source .env.local
        set +a
    fi
    
    # Validate required variables
    validate_global_config
}

load_service_config() {
    local service_name=$1
    local service_env_file="${service_name}/.env"
    
    # Load global config first
    load_global_config
    
    # Load service-specific config
    if [ -f "$service_env_file" ]; then
        echo "📄 Loading $service_name config from $service_env_file"
        set -a
        source "$service_env_file"
        set +a
    fi
}

validate_global_config() {
    local required_vars=(
        "PROJECT_NAME"
        "DB_HOST" "DB_PORT" "DB_NAME"
        "MSSQL_SA_PASSWORD"
        "MSSQL_APP_USER" "MSSQL_APP_PASSWORD"
        "DB_CONTAINER_NAME"
    )
    
    echo "🔍 Validating configuration..."
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "❌ Missing required variable: $var"
            echo "💡 Please check your .env file"
            exit 1
        fi
    done
    
    echo "✅ Configuration validation passed"
}

# Export functions for use in other scripts
export -f load_global_config
export -f load_service_config
export -f validate_global_config