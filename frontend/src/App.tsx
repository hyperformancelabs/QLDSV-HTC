import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { MainLayout } from '@/layouts/main-layout';
import LoginPage from '@/pages/login';
import DashboardPage from '@/pages/dashboard';
import HealthPage from '@/pages/health';
import { Toaster } from '@/components/ui/toaster';
import SubjectsPage from '@/pages/subjects';
import ClassManagementPage from '@/pages/class-management';
import LecturerAccounts from './pages/lecturer-accounts';
import CreditClassesPage from './pages/credit-classes';
import StudentRegistrationsPage from './pages/student-registrations';

// Demo placeholder page component for routes still under development
const PlaceholderPage = ({ title }: { title: string }) => (
  <div className="flex flex-col items-center justify-center py-12">
    <h1 className="text-2xl font-bold mb-4">{title}</h1>
    <p className="text-muted-foreground">
      Trang này đang được phát triển. Đây là giao diện demo.
    </p>
  </div>
);

function App() {
  return (
    <Router>
      <Routes>
        {/* Public routes (no auth required) */}
        <Route path="/login" element={<LoginPage />} />
        <Route path="/health" element={<HealthPage />} />
        
        {/* Protected routes (require auth) */}
        <Route element={<MainLayout />}>
          {/* Redirect root to dashboard */}
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="/dashboard" element={<DashboardPage />} />
          
          {/* Faculty management */}
          <Route path="/faculties" element={<PlaceholderPage title="Quản lý khoa" />} />
          
          {/* Class management */}
          <Route path="/classes" element={<ClassManagementPage />} />
          
          {/* Student management */}
          <Route path="/students" element={<PlaceholderPage title="Quản lý sinh viên" />} />
          
          {/* Teacher management */}
          <Route path="/teachers" element={<PlaceholderPage title="Quản lý giảng viên" />} />
          
          {/* Subject management - implemented */}
          <Route path="/subjects" element={<SubjectsPage />} />
          
          {/* Credit class management - implemented */}
          <Route path="/credit-classes" element={<CreditClassesPage />} />
          
          {/* Registration management - implemented */}
          <Route path="/registrations" element={<StudentRegistrationsPage />} />
          
          {/* Grade management */}
          <Route path="/grades" element={<PlaceholderPage title="Quản lý điểm" />} />
          
          {/* Tuition management */}
          <Route path="/tuition" element={<PlaceholderPage title="Quản lý học phí" />} />
          
          {/* Reports */}
          <Route path="/reports" element={<PlaceholderPage title="Báo cáo thống kê" />} />
          
          {/* System management */}
          <Route path="/system" element={<PlaceholderPage title="Quản lý hệ thống" />} />
          
          {/* Settings */}
          <Route path="/settings" element={<PlaceholderPage title="Cài đặt" />} />
          
          {/* Profile */}
          <Route path="/profile" element={<PlaceholderPage title="Hồ sơ cá nhân" />} />
          
          {/* Lecturer accounts */}
          <Route path="/lecturer-accounts" element={<LecturerAccounts />} />
          
          {/* 404 - Not Found */}
          <Route path="*" element={<PlaceholderPage title="404 - Không tìm thấy trang" />} />
        </Route>
      </Routes>
      
      {/* Global toast container */}
      <Toaster />
    </Router>
  );
}

export default App; 