# SQL Server 2022 Customized for QLDSV-HTC
FROM mcr.microsoft.com/mssql/server:2022-latest

# Accept EULA
ENV ACCEPT_EULA=Y

# Set working directory
WORKDIR /app

# Setup as root for installation
USER root

# Create directories and set permissions
RUN mkdir -p /home/mssql /var/scripts /var/backups /var/health /var/opt/mssql/log \
    && chown -R mssql:mssql /home/mssql /var/scripts /var/backups /var/health /var/opt/mssql

# Install dependencies
RUN apt-get update \
    && apt-get install -y \
        curl \
        apt-transport-https \
        gnupg \
        unixodbc-dev \
        unixodbc \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
        mssql-tools18 \
        msodbcsql18 \
    && echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> /root/.bashrc \
    && echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> /home/mssql/.bashrc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set PATH for tools
ENV PATH="$PATH:/opt/mssql-tools18/bin"

# Copy health check script
COPY health/healthcheck.sh /var/health/
RUN chmod +x /var/health/healthcheck.sh

# Copy all database scripts with new structure
COPY 01-foundation/ /var/scripts/01-foundation/
COPY 02-schema/ /var/scripts/02-schema/
COPY 03-security/ /var/scripts/03-security/
COPY 04-backup/ /var/scripts/04-backup/
COPY 05-data/ /var/scripts/05-data/

# Set permissions
RUN find /var/scripts -name "*.sql" -exec chmod +r {} \;
RUN find /var/scripts -name "*.sh" -exec chmod +x {} \;

# Switch back to mssql user
USER mssql

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=5 --start-period=30s \
    CMD /var/health/healthcheck.sh