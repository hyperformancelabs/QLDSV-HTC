#!/bin/bash

# Health check script for SQL Server container
# Returns 0 if healthy, 1 if unhealthy

# Check if SQL Server is responding
/opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$SA_PASSWORD" \
    -C \
    -Q "SELECT 1" \
    -t 5 \
    > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ SQL Server is healthy"
    exit 0
else
    echo "❌ SQL Server is not responding"
    exit 1
fi 