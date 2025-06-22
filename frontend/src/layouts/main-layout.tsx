import React, { useState, useEffect } from 'react';
import { Outlet, useLocation, useNavigate } from 'react-router-dom';
import { Sidebar } from '@/layouts/sidebar';
import { Header } from '@/layouts/header';
import { useAuthStore } from '@/store/use-auth-store';
import { Toaster } from '@/components/ui/toaster';
import { APP_NAME, SIDEBAR_WIDTH_EXPANDED, SIDEBAR_WIDTH_COLLAPSED } from '@/lib/config';

export function MainLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const { isAuthenticated } = useAuthStore();
  const location = useLocation();
  const navigate = useNavigate();

  // Redirect to login if not authenticated
  useEffect(() => {
    if (!isAuthenticated && location.pathname !== '/login' && location.pathname !== '/health') {
      navigate('/login');
    }
  }, [isAuthenticated, location.pathname, navigate]);

  // Special case for health check page - no sidebar or header
  if (location.pathname === '/health') {
    return (
      <div className="min-h-screen bg-background">
        <Outlet />
        <Toaster />
      </div>
    );
  }

  // Special case for login page - no sidebar or header
  if (location.pathname === '/login') {
    return (
      <div className="min-h-screen bg-background">
        <Outlet />
        <Toaster />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <Header sidebarOpen={sidebarOpen} onOpenChange={setSidebarOpen} />
      <Sidebar open={sidebarOpen} onOpenChange={setSidebarOpen} />
      <div 
        className="flex flex-col min-h-screen pt-[60px]"
        style={{ 
          marginLeft: sidebarOpen ? SIDEBAR_WIDTH_EXPANDED : SIDEBAR_WIDTH_COLLAPSED,
          transition: "margin 0.3s cubic-bezier(0.4, 0, 0.2, 1)"
        }}
      >
        <main className="flex-1 p-4 md:p-6">
          <Outlet />
        </main>
        <footer className="border-t py-3 px-6 text-center text-xs text-muted-foreground">
          <p>© {new Date().getFullYear()} {APP_NAME}. Hệ thống quản lý điểm sinh viên theo hệ tín chỉ.</p>
        </footer>
      </div>
      <Toaster />
    </div>
  );
} 