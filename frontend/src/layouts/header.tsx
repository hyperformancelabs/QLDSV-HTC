import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Menu, Bell, Sun, Moon, ChevronDown, LogOut, User, Settings, Search } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useAuthStore } from '@/store/use-auth-store';
import * as authService from '@/services/authService';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Input } from '@/components/ui/input';
import { UserRole } from '@/types';
import { APP_NAME } from '@/lib/config';
import { toast } from '@/components/ui/use-toast';

interface HeaderProps {
  sidebarOpen: boolean;
  onOpenChange: (open: boolean) => void;
}

export function Header({ sidebarOpen, onOpenChange }: HeaderProps) {
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();
  const [theme, setTheme] = React.useState<'light' | 'dark'>('light');

  const toggleTheme = () => {
    const newTheme = theme === 'light' ? 'dark' : 'light';
    setTheme(newTheme);
    document.documentElement.classList.toggle('dark', newTheme === 'dark');
  };

  const handleLogout = async () => {
    try {
      await authService.logout();
    } catch (err) {
      // ignore network error, proceed client-side
      /* empty */
    } finally {
      toast.success({
        title: 'Đăng xuất thành công',
        description: 'Hẹn gặp lại!' 
      });
      logout();
      setTimeout(() => navigate('/login'), 300);
    }
  };

  const getRoleLabel = (role: UserRole) => {
    switch (role) {
      case UserRole.PGV:
        return 'Phòng Giáo Vụ';
      case UserRole.KHOA:
        return 'Khoa';
      case UserRole.SV:
        return 'Sinh Viên';
      default:
        return role;
    }
  };

  const getUserInitials = () => {
    if (!user) return 'U';
    
    const firstInitial = user.ho ? user.ho.charAt(0) : '';
    const lastInitial = user.ten ? user.ten.charAt(0) : '';
    
    return `${firstInitial}${lastInitial}`;
  };

  return (
    <header className="sticky top-0 z-30 flex h-16 w-full items-center gap-4 border-b bg-background px-4 md:px-6 lg:h-[60px]">
      <Button 
        variant="ghost" 
        size="icon" 
        onClick={() => onOpenChange(!sidebarOpen)}
        className="text-muted-foreground"
      >
        <Menu className="h-5 w-5" />
        <span className="sr-only">Toggle menu</span>
      </Button>
      
      <div className="bg-gradient-to-r from-blue-600 to-blue-800 bg-clip-text text-transparent font-bold text-xl">
        {APP_NAME}
      </div>
      
      <div className="flex-1 flex items-center justify-end gap-4">
        <div className="relative md:w-64">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            type="search"
            placeholder="Tìm kiếm..."
            className="pl-8 rounded-full bg-muted"
          />
        </div>
        
        <Button variant="ghost" size="icon" className="text-muted-foreground" onClick={toggleTheme}>
          {theme === 'light' ? <Moon className="h-5 w-5" /> : <Sun className="h-5 w-5" />}
          <span className="sr-only">Toggle theme</span>
        </Button>
        
        <Button variant="ghost" size="icon" className="text-muted-foreground relative">
          <Bell className="h-5 w-5" />
          <span className="absolute top-1 right-1 h-2 w-2 rounded-full bg-primary"></span>
          <span className="sr-only">Notifications</span>
        </Button>
        
        {user && (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" className="flex items-center gap-2 pl-1 pr-2">
                <Avatar className="h-8 w-8 border">
                  <AvatarImage src="" alt={user.username} />
                  <AvatarFallback className="bg-primary/10 text-primary">{getUserInitials()}</AvatarFallback>
                </Avatar>
                <div className="hidden md:flex flex-col items-start">
                  <span className="text-sm font-medium leading-none">{user.ho} {user.ten}</span>
                  <span className="text-xs text-muted-foreground">{getRoleLabel(user.role)}</span>
                </div>
                <ChevronDown className="h-4 w-4 text-muted-foreground" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-56">
              <DropdownMenuLabel>
                <div className="flex flex-col space-y-1">
                  <p className="text-sm font-medium leading-none">{user.ho} {user.ten}</p>
                  <p className="text-xs leading-none text-muted-foreground">{user.username}</p>
                </div>
              </DropdownMenuLabel>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={() => navigate('/profile')} className="cursor-pointer">
                <User className="mr-2 h-4 w-4" />
                <span>Hồ sơ cá nhân</span>
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => navigate('/settings')} className="cursor-pointer">
                <Settings className="mr-2 h-4 w-4" />
                <span>Cài đặt</span>
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={handleLogout} className="cursor-pointer text-destructive focus:text-destructive">
                <LogOut className="mr-2 h-4 w-4" />
                <span>Đăng xuất</span>
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        )}
      </div>
    </header>
  );
} 