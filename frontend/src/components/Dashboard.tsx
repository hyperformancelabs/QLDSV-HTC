import React from 'react';
import { Card, Button, Typography, Space, Avatar, message } from 'antd';
import { LogoutOutlined, UserOutlined } from '@ant-design/icons';
import authService from '../services/authService';

const { Title, Text } = Typography;

interface DashboardProps {
  user: any;
  onLogout: () => void;
}

const Dashboard: React.FC<DashboardProps> = ({ user, onLogout }) => {
  const handleLogout = async () => {
    try {
      await authService.logout();
      message.success('Đăng xuất thành công');
      onLogout();
    } catch (error) {
      console.error('Logout error:', error);
      onLogout(); // Still logout even if API call fails
    }
  };

  return (
    <div style={{ 
      minHeight: '100vh', 
      background: '#f0f2f5', 
      padding: '24px' 
    }}>
      <Card style={{ maxWidth: '800px', margin: '0 auto' }}>
        <div style={{ textAlign: 'center', marginBottom: '32px' }}>
          <Avatar size={64} icon={<UserOutlined />} style={{ marginBottom: '16px' }} />
          <Title level={2}>Chào mừng đến với Hệ thống QLDSV-HTC</Title>
          <Text type="secondary">Hệ thống quản lý điểm sinh viên theo hệ tín chỉ</Text>
        </div>

        <Card style={{ marginBottom: '24px' }}>
          <Title level={4}>Thông tin người dùng</Title>
          <Space direction="vertical" size="small">
            <Text><strong>Họ tên:</strong> {user.ho} {user.ten}</Text>
            <Text><strong>Vai trò:</strong> {user.role}</Text>
            {user.masv && <Text><strong>Mã sinh viên:</strong> {user.masv}</Text>}
            {user.magv && <Text><strong>Mã giảng viên:</strong> {user.magv}</Text>}
            {user.malop && <Text><strong>Lớp:</strong> {user.malop}</Text>}
            {user.makhoa && <Text><strong>Khoa:</strong> {user.makhoa}</Text>}
          </Space>
        </Card>

        <div style={{ textAlign: 'center' }}>
          <Button 
            type="primary" 
            danger 
            icon={<LogoutOutlined />}
            onClick={handleLogout}
            size="large"
          >
            Đăng xuất
          </Button>
        </div>
      </Card>
    </div>
  );
};

export default Dashboard; 