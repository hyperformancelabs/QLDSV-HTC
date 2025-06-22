import React from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { 
  GraduationCap,
  BookOpen,
  CalendarRange,
  ClipboardList,
  FileText,
  DollarSign,
  Settings,
  Building,
  School,
  User,
  BarChart4,
  Home
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { useAuthStore } from '@/store/use-auth-store';
import { UserRole } from '@/types';
import { APP_NAME, APP_VERSION, SIDEBAR_WIDTH_EXPANDED, SIDEBAR_WIDTH_COLLAPSED } from '@/lib/config';

interface SidebarProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

interface NavItem {
  title: string;
  href: string;
  icon: React.ReactNode;
  roles: UserRole[];
}

export function Sidebar({ open, onOpenChange }: SidebarProps) {
  const { user } = useAuthStore();
  const location = useLocation();

  // Simplified menu structure based on the image
  const navItems: NavItem[] = [
    {
      title: 'Trang chủ',
      href: '/dashboard',
      icon: <Home className="h-5 w-5" />,
      roles: [UserRole.PGV, UserRole.KHOA, UserRole.SV],
    },
    {
      title: 'Môn học',
      href: '/subjects',
      icon: <BookOpen className="h-5 w-5" />,
      roles: [UserRole.PGV, UserRole.KHOA, UserRole.SV],
    },
    {
      title: 'Giảng viên',
      href: '/teachers',
      icon: <User className="h-5 w-5" />,
      roles: [UserRole.PGV, UserRole.KHOA],
    },
    {
      title: 'Lớp',
      href: '/classes',
      icon: <School className="h-5 w-5" />,
      roles: [UserRole.PGV, UserRole.KHOA],
    },
    {
      title: 'Lớp tín chỉ',
      href: '/credit-classes',
      icon: <CalendarRange className="h-5 w-5" />,
      roles: [UserRole.PGV, UserRole.KHOA, UserRole.SV],
    },
    {
      title: 'Điểm',
      href: '/grades',
      icon: <FileText className="h-5 w-5" />,
      roles: [UserRole.PGV, UserRole.KHOA, UserRole.SV],
    },
    {
      title: 'Học phí & Phục vụ',
      href: '/tuition',
      icon: <DollarSign className="h-5 w-5" />,
      roles: [UserRole.PGV, UserRole.SV],
    },
    {
      title: 'Báo cáo',
      href: '/reports',
      icon: <BarChart4 className="h-5 w-5" />,
      roles: [UserRole.PGV, UserRole.KHOA],
    },
    {
      title: 'Cài đặt',
      href: '/settings',
      icon: <Settings className="h-5 w-5" />,
      roles: [UserRole.PGV, UserRole.KHOA, UserRole.SV],
    },
  ];

  // Filter nav items based on user role
  const filteredNavItems = navItems.filter(
    (item) => user && item.roles.includes(user.role)
  );

  return (
    <>
      {/* Overlay for mobile */}
      {open && (
        <div 
          className="fixed inset-0 z-40 bg-background/80 backdrop-blur-sm lg:hidden"
          onClick={() => onOpenChange(false)}
        />
      )}
      
      {/* Sidebar */}
      <div 
        className={cn(
          "fixed top-[60px] left-0 z-40 h-[calc(100vh-60px)] border-r bg-background transition-all duration-300",
          open ? "w-72" : "w-16",
        )}
        style={{ 
          width: open ? SIDEBAR_WIDTH_EXPANDED : SIDEBAR_WIDTH_COLLAPSED 
        }}
      >
        {/* Navigation */}
        <div className="flex flex-col h-full">
          <div className="flex-1 overflow-y-auto py-3">
            <div className="space-y-1 px-3">
              {filteredNavItems.map((item) => (
                <NavLink
                  key={item.href}
                  to={item.href}
                  className={({ isActive }) => cn(
                    "flex items-center whitespace-nowrap rounded-md px-3 py-2 text-sm font-medium transition-colors",
                    isActive 
                      ? "bg-primary text-primary-foreground" 
                      : "text-muted-foreground hover:bg-muted hover:text-foreground",
                    !open && "justify-center px-0"
                  )}
                >
                  <div className="flex-shrink-0 w-5 h-5 flex items-center justify-center">
                    {item.icon}
                  </div>
                  {open && (
                    <span className="ml-3 overflow-hidden text-ellipsis">{item.title}</span>
                  )}
                </NavLink>
              ))}
            </div>
          </div>
          
          {/* Footer */}
          <div className={cn(
            "border-t transition-all duration-300",
            open ? "p-4" : "p-2 text-center"
          )}>
            <div className="text-xs text-muted-foreground whitespace-nowrap">
              {open ? (
                <>
                  <div className="truncate">{APP_NAME} v{APP_VERSION}</div>
                  <div className="truncate">© {new Date().getFullYear()}</div>
                </>
              ) : (
                <>
                  <div className="truncate">v{APP_VERSION}</div>
                  <div className="truncate">© {new Date().getFullYear()}</div>
                </>
              )}
            </div>
          </div>
        </div>
      </div>
    </>
  );
} 