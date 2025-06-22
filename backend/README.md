# QLDSV-HTC Backend

This directory contains the FastAPI backend for the Student Transcript Management System.

## Quick Start

### 1. Prerequisites

- Python 3.10+
- Pip (Python package installer)
- ODBC Driver for SQL Server

### 2. Installation

All commands should be run from the project root (`QLDSV-HTC/`).

1.  **Create a virtual environment:**

    ```bash
    python3 -m venv backend/venv
    ```

2.  **Activate the virtual environment:**

    -   On macOS/Linux:
        ```bash
        source backend/venv/bin/activate
        ```
    -   On Windows:
        ```bash
        .\backend\venv\Scripts\activate
        ```

3.  **Install dependencies:**

    ```bash
    pip install -r backend/requirements.txt
    ```

### 3. Environment Configuration

1.  Copy the example environment file:

    ```bash
    cp backend/.env.example backend/.env
    ```

2.  Review and update the variables in `backend/.env` as needed. The backend inherits global settings from the root `.env` file, so ensure that is also configured.

### 4. Running the Application

-   **To start the development server:**

    ```bash
    uvicorn backend.main:app --reload
    ```

    The API will be available at `http://localhost:8000`.

-   **To reset the database:**
    Pass the `--reset-db` flag when running the application. This will drop all existing data and re-run all SQL scripts from the `database/` directory before starting the server.

    ```bash
    python backend/main.py --reset-db
    ```

-   **Using the provided script:**
    The `start-backend.sh` script automates the setup and execution process. To reset the database with the script, use:
    
    ```bash
    ./scripts/start-backend.sh --reset-db
    ```

## Project Structure

```
backend/
├── app/                  # Main application source code
│   ├── api/              # API endpoints, routers, dependencies
│   ├── core/             # Core logic (app factory, config, logging)
│   ├── db/               # Database connection, repositories
│   ├── schemas/          # Pydantic schemas (data models)
│   ├── services/         # Business logic
│   └── utils/            # Utility helpers (e.g., db reset)
├── logs/                 # Log files
├── main.py               # Application entry point for Uvicorn
├── requirements.txt      # Python dependencies
└── venv/                 # Python virtual environment (ignored)
```
