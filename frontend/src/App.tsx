import React, { useEffect, useState } from 'react';
import './styles/App.css';

// Define types for API responses
interface HealthResponse {
  status: string;
  database: {
    connected: boolean;
    version?: string;
    error?: string;
    message?: string;
    solution?: string;
  };
  api?: {
    status: string;
    message: string;
  };
}

function App() {
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [responseDetails, setResponseDetails] = useState<string | null>(null);

  // Hardcode API URL to ensure no whitespace issues
  const apiUrl = 'http://localhost:8000';
  
  useEffect(() => {
    console.log("Using API URL:", apiUrl);
    
    const checkBackendHealth = async () => {
      try {
        setLoading(true);
        console.log("Fetching from:", `${apiUrl}/health`);
        
        const response = await fetch(`${apiUrl}/health`, {
          method: 'GET',
          headers: {
            'Accept': 'application/json'
          }
        });
        
        // Get response text to debug
        const responseText = await response.text();
        console.log("Raw response:", responseText);
        
        if (!response.ok) {
          throw new Error(`API responded with status: ${response.status} - ${responseText}`);
        }
        
        // Try parsing the response as JSON
        try {
          const data = JSON.parse(responseText) as HealthResponse;
          setHealth(data);
          setError(null);
        } catch (parseError) {
          console.error("JSON parse error:", parseError);
          setResponseDetails(responseText.substring(0, 100) + "...");
          throw new Error(`Failed to parse response as JSON: ${parseError instanceof Error ? parseError.message : String(parseError)}`);
        }
      } catch (err) {
        console.error('Error checking backend health:', err);
        setError(err instanceof Error ? err.message : 'An unknown error occurred');
        setHealth(null);
      } finally {
        setLoading(false);
      }
    };

    checkBackendHealth();
  }, [apiUrl]);

  return (
    <div className="app-container">
      <header className="app-header">
        <h1>QLDSV-HTC Frontend</h1>
        <p>Quản lý điểm sinh viên hệ tín chỉ</p>
      </header>

      <main className="app-content">
        <section className="health-status">
          <h2>Backend Connection Status</h2>
          
          <div className="api-info">
            <p>API URL: {apiUrl}</p>
          </div>
          
          {loading ? (
            <div className="loading">Checking backend connection...</div>
          ) : error ? (
            <div className="error">
              <h3>Connection Error</h3>
              <p>{error}</p>
              {responseDetails && (
                <div className="response-details">
                  <h4>Response details:</h4>
                  <pre>{responseDetails}</pre>
                </div>
              )}
              <p>Please check if the backend server is running at {apiUrl}</p>
            </div>
          ) : health ? (
            <div className={`status ${health.status === 'healthy' ? 'healthy' : health.status === 'warning' ? 'warning' : 'unhealthy'}`}>
              <h3>Backend Status: {health.status}</h3>
              
              {health.api && (
                <div className="api-status">
                  <h4>API Status: {health.api.status}</h4>
                  <p>{health.api.message}</p>
                </div>
              )}
              
              <div className="database-status">
                <h4>Database Connection</h4>
                {health.database.connected ? (
                  <>
                    <p className="success">✓ Connected to database</p>
                    {health.database.version && (
                      <p className="version">Database version: {health.database.version}</p>
                    )}
                  </>
                ) : (
                  <>
                    <p className="failure">✗ Database connection failed</p>
                    {health.database.error && (
                      <p className="error-message">Error: {health.database.error}</p>
                    )}
                    {health.database.message && (
                      <div className="database-message">
                        <p>{health.database.message}</p>
                      </div>
                    )}
                    {health.database.solution && (
                      <div className="solution">
                        <h5>Solution:</h5>
                        <p>{health.database.solution}</p>
                      </div>
                    )}
                  </>
                )}
              </div>
            </div>
          ) : (
            <div className="no-data">No data available</div>
          )}
        </section>
      </main>

      <footer className="app-footer">
        <p>QLDSV-HTC &copy; {new Date().getFullYear()}</p>
      </footer>
    </div>
  );
}

export default App;
