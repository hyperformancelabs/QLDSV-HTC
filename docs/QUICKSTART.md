# QLDSV-HTC Quick Start Guide

This guide will help you quickly set up and run the QLDSV-HTC system.

## Prerequisites

1. **SQL Server**: Docker container or local SQL Server instance running on port 1434
2. **Node.js**: Version 16 or higher
3. **Python**: Version 3.8 or higher
4. **ODBC Driver for SQL Server**: ODBC Driver 18 for SQL Server

## Initial Setup

### 1. Set up environment

The system uses environment variables defined in `.env` files:

- Root `.env` at the project root
- Component-specific `.env` files in `/backend` and `/frontend` directories

Run the following commands to set up each component:

```bash
# Database setup (if using Docker)
./scripts/setup/db/setup-database.sh

# Backend setup
./scripts/setup/be/setup-backend.sh

# Frontend setup
./scripts/setup/fe/setup-frontend.sh
```

### 2. Start the system

You can start each component separately:

```bash
# Start database
./scripts/start-database.sh

# Start backend with database reset (creates fresh database)
./scripts/start-backend.sh --reset-db

# Start backend without database reset
./scripts/start-backend.sh

# Start frontend
./scripts/start-frontend.sh
```

Or use the full default setup which checks and installs dependencies:

```bash
# Full setup with database reset
./scripts/start-database.sh --full-default-setup
./scripts/start-backend.sh --full-default-setup --reset-db
./scripts/start-frontend.sh --full-default-setup
```

## Accessing the System

- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **Frontend UI**: http://localhost:5173

## Project Structure

- `/database`: SQL Server scripts organized by function
  - `/01-foundation`: Database creation scripts
  - `/02-schema`: Table schema definitions
  - ...

- `/backend`: FastAPI application
  - `/app`: API endpoints, services, and core functionality
  - `/logs`: Application logs

- `/frontend`: React application
  - `/src`: Components, pages, and services
  - `/public`: Static assets

- `/scripts`: Utility scripts for setup and operation
  - `/setup`: Initial setup scripts for each component
  - `/utils`: Utility scripts for each component

## Development Workflow

1. Start the database first
2. Start the backend with `--reset-db` flag if you want a fresh database
3. Start the frontend
4. Access the frontend at http://localhost:5173 to verify connectivity 