#!/bin/bash

# Health check script for SQL Server container
# Returns 0 if healthy, 1 if unhealthy

# Check if SQL Server process is running
if ! pgrep -x "sqlservr" > /dev/null; then
    echo "❌ SQL Server process is not running"
    exit 1
fi

# Check if SQL Server is responding to queries
/opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$SA_PASSWORD" \
    -C \
    -Q "SELECT @@VERSION AS SQLServerVersion, SERVERPROPERTY('Collation') AS Collation" \
    -t 5 \
    > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ SQL Server is healthy"
    exit 0
else
    echo "❌ SQL Server is not responding to queries"
    
    # Check if SQL Server is still starting up
    if grep -q "Server is starting up" /var/opt/mssql/log/errorlog 2>/dev/null; then
        echo "⏳ SQL Server is still starting up"
    fi
    
    # Check for authentication errors
    if grep -q "Login failed" /var/opt/mssql/log/errorlog 2>/dev/null; then
        echo "🔑 Authentication error detected"
    fi
    
    exit 1
fi 