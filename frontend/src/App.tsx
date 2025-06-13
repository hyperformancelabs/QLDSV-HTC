import React, { useState, useEffect } from 'react';
import { ConfigProvider, message } from 'antd';
import viVN from 'antd/locale/vi_VN';
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import authService from './services/authService';
import 'antd/dist/reset.css';

function App() {
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  // Check if user is already logged in
  useEffect(() => {
    checkAuthStatus();
  }, []);

  const checkAuthStatus = async () => {
    try {
      const currentUser = await authService.getCurrentUser();
      setUser(currentUser);
    } catch (error) {
      console.log('No user logged in');
    } finally {
      setLoading(false);
    }
  };

  const handleLoginSuccess = (userData: any) => {
    setUser(userData);
  };

  const handleLogout = () => {
    setUser(null);
  };

  // Show loading screen while checking auth status
  if (loading) {
    return (
      <div style={{
        height: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
      }}>
        <div style={{ textAlign: 'center', color: 'white' }}>
          <div style={{ fontSize: '18px', marginBottom: '16px' }}>
            Đang kiểm tra trạng thái đăng nhập...
          </div>
        </div>
      </div>
    );
  }

  return (
    <ConfigProvider locale={viVN}>
      <div className="App">
        {user ? (
          <Dashboard user={user} onLogout={handleLogout} />
        ) : (
          <Login onLoginSuccess={handleLoginSuccess} />
        )}
      </div>
    </ConfigProvider>
  );
}

export default App;
