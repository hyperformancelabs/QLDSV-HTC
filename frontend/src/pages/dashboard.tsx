import React from 'react';
import { Link } from 'react-router-dom';
import { 
  Users, 
  BookOpen, 
  CalendarRange, 
  ClipboardList, 
  FileText,
  DollarSign, 
  BarChart4,
  User,
  ArrowRight
} from 'lucide-react';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useAuthStore } from '@/store/use-auth-store';
import { UserRole } from '@/types';

interface StatCardProps {
  title: string;
  value: string | number;
  description: string;
  icon: React.ReactNode;
  trend?: {
    value: number;
    label: string;
  };
  color?: string;
}

interface QuickActionCardProps {
  title: string;
  description: string;
  icon: React.ReactNode;
  href: string;
  color?: string;
}

const StatCard: React.FC<StatCardProps> = ({ title, value, description, icon, trend, color = 'bg-blue-500' }) => (
  <Card>
    <CardHeader className="flex flex-row items-center justify-between pb-2">
      <CardTitle className="text-sm font-medium">{title}</CardTitle>
      <div className={`${color} text-white p-2 rounded-md`}>
        {icon}
      </div>
    </CardHeader>
    <CardContent>
      <div className="text-2xl font-bold">{value}</div>
      <p className="text-xs text-muted-foreground">{description}</p>
    </CardContent>
    {trend && (
      <CardFooter>
        <p className={`text-xs ${trend.value >= 0 ? 'text-green-600' : 'text-red-600'}`}>
          {trend.value >= 0 ? '↑' : '↓'} {Math.abs(trend.value)}% {trend.label}
        </p>
      </CardFooter>
    )}
  </Card>
);

const QuickActionCard: React.FC<QuickActionCardProps> = ({ title, description, icon, href, color = 'bg-blue-500' }) => (
  <Card>
    <CardHeader className="flex flex-row items-center justify-between pb-2">
      <div className={`${color} text-white p-2 rounded-md`}>
        {icon}
      </div>
    </CardHeader>
    <CardContent>
      <CardTitle className="text-lg">{title}</CardTitle>
      <CardDescription className="mt-2">{description}</CardDescription>
    </CardContent>
    <CardFooter>
      <Link to={href} className="w-full">
        <Button variant="outline" className="w-full justify-between">
          <span>Truy cập</span>
          <ArrowRight className="h-4 w-4" />
        </Button>
      </Link>
    </CardFooter>
  </Card>
);

export default function DashboardPage() {
  const { user } = useAuthStore();
  const role = user?.role || UserRole.SV;
  
  // Mock stats based on user role
  const getStats = () => {
    switch (role) {
      case UserRole.PGV:
        return [
          { title: 'Tổng số sinh viên', value: '2,845', description: 'Sinh viên đang học', icon: <Users className="h-4 w-4" />, trend: { value: 5.25, label: 'so với kỳ trước' }, color: 'bg-blue-500' },
          { title: 'Tổng số lớp tín chỉ', value: '128', description: 'Học kỳ hiện tại', icon: <CalendarRange className="h-4 w-4" />, trend: { value: 12, label: 'so với kỳ trước' }, color: 'bg-green-500' },
          { title: 'Đăng ký lớp tín chỉ', value: '1,245', description: 'Học kỳ hiện tại', icon: <ClipboardList className="h-4 w-4" />, trend: { value: 8.5, label: 'so với kỳ trước' }, color: 'bg-purple-500' },
          { title: 'Học phí chưa đóng', value: '325tr', description: 'VND', icon: <DollarSign className="h-4 w-4" />, trend: { value: -3.2, label: 'so với kỳ trước' }, color: 'bg-red-500' },
        ];
      case UserRole.KHOA:
        return [
          { title: 'Sinh viên khoa', value: '845', description: 'Sinh viên đang học', icon: <Users className="h-4 w-4" />, trend: { value: 2.5, label: 'so với kỳ trước' }, color: 'bg-blue-500' },
          { title: 'Lớp tín chỉ khoa', value: '42', description: 'Học kỳ hiện tại', icon: <CalendarRange className="h-4 w-4" />, trend: { value: 5, label: 'so với kỳ trước' }, color: 'bg-green-500' },
          { title: 'Đăng ký lớp tín chỉ', value: '512', description: 'Học kỳ hiện tại', icon: <ClipboardList className="h-4 w-4" />, trend: { value: 4.2, label: 'so với kỳ trước' }, color: 'bg-purple-500' },
          { title: 'Điểm trung bình', value: '7.5', description: 'Toàn khoa', icon: <FileText className="h-4 w-4" />, trend: { value: 0.3, label: 'so với kỳ trước' }, color: 'bg-amber-500' },
        ];
      case UserRole.SV:
        return [
          { title: 'Số tín chỉ đã đạt', value: '85', description: 'Trên tổng 150', icon: <BookOpen className="h-4 w-4" />, trend: { value: 10, label: 'so với kỳ trước' }, color: 'bg-blue-500' },
          { title: 'Điểm trung bình', value: '7.8', description: 'Tích lũy', icon: <FileText className="h-4 w-4" />, trend: { value: 0.2, label: 'so với kỳ trước' }, color: 'bg-green-500' },
          { title: 'Đăng ký lớp tín chỉ', value: '5', description: 'Học kỳ hiện tại', icon: <ClipboardList className="h-4 w-4" />, trend: { value: 0, label: 'so với kỳ trước' }, color: 'bg-purple-500' },
          { title: 'Học phí chưa đóng', value: '8.5tr', description: 'VND', icon: <DollarSign className="h-4 w-4" />, trend: { value: -15, label: 'so với kỳ trước' }, color: 'bg-red-500' },
        ];
      default:
        return [];
    }
  };
  
  // Quick actions based on user role
  const getQuickActions = () => {
    switch (role) {
      case UserRole.PGV:
        return [
          { title: 'Quản lý sinh viên', description: 'Thêm, sửa, xóa thông tin sinh viên', icon: <Users className="h-4 w-4" />, href: '/students', color: 'bg-blue-500' },
          { title: 'Quản lý lớp tín chỉ', description: 'Mở lớp, cập nhật thông tin lớp', icon: <CalendarRange className="h-4 w-4" />, href: '/credit-classes', color: 'bg-green-500' },
          { title: 'Nhập điểm', description: 'Nhập và cập nhật điểm sinh viên', icon: <FileText className="h-4 w-4" />, href: '/grades', color: 'bg-amber-500' },
          { title: 'Báo cáo', description: 'Xem các báo cáo thống kê', icon: <BarChart4 className="h-4 w-4" />, href: '/reports', color: 'bg-purple-500' },
        ];
      case UserRole.KHOA:
        return [
          { title: 'Quản lý lớp tín chỉ', description: 'Mở lớp, cập nhật thông tin lớp', icon: <CalendarRange className="h-4 w-4" />, href: '/credit-classes', color: 'bg-green-500' },
          { title: 'Nhập điểm', description: 'Nhập và cập nhật điểm sinh viên', icon: <FileText className="h-4 w-4" />, href: '/grades', color: 'bg-amber-500' },
          { title: 'Quản lý môn học', description: 'Xem và cập nhật thông tin môn học', icon: <BookOpen className="h-4 w-4" />, href: '/subjects', color: 'bg-blue-500' },
          { title: 'Báo cáo', description: 'Xem các báo cáo thống kê', icon: <BarChart4 className="h-4 w-4" />, href: '/reports', color: 'bg-purple-500' },
        ];
      case UserRole.SV:
        return [
          { title: 'Đăng ký lớp tín chỉ', description: 'Đăng ký và hủy lớp tín chỉ', icon: <ClipboardList className="h-4 w-4" />, href: '/registrations', color: 'bg-blue-500' },
          { title: 'Xem điểm', description: 'Xem điểm các môn học', icon: <FileText className="h-4 w-4" />, href: '/grades', color: 'bg-green-500' },
          { title: 'Học phí', description: 'Xem thông tin học phí', icon: <DollarSign className="h-4 w-4" />, href: '/tuition', color: 'bg-red-500' },
          { title: 'Hồ sơ cá nhân', description: 'Xem và cập nhật thông tin cá nhân', icon: <User className="h-4 w-4" />, href: '/profile', color: 'bg-purple-500' },
        ];
      default:
        return [];
    }
  };
  
  const stats = getStats();
  const quickActions = getQuickActions();
  
  // Welcome message based on role
  const getWelcomeMessage = () => {
    const currentHour = new Date().getHours();
    let greeting = 'Chào buổi sáng';
    
    if (currentHour >= 12 && currentHour < 18) {
      greeting = 'Chào buổi chiều';
    } else if (currentHour >= 18) {
      greeting = 'Chào buổi tối';
    }
    
    const roleLabel = role === UserRole.PGV ? 'Phòng Giáo Vụ' : role === UserRole.KHOA ? 'Khoa' : 'Sinh viên';
    return `${greeting}, ${roleLabel} ${user?.ho} ${user?.ten}!`;
  };
  
  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-3xl font-bold tracking-tight">{getWelcomeMessage()}</h2>
        <p className="text-muted-foreground">
          Đây là tổng quan về hệ thống quản lý điểm sinh viên theo hệ tín chỉ.
        </p>
      </div>
      
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat, index) => (
          <StatCard
            key={index}
            title={stat.title}
            value={stat.value}
            description={stat.description}
            icon={stat.icon}
            trend={stat.trend}
            color={stat.color}
          />
        ))}
      </div>
      
      <div>
        <h3 className="text-xl font-semibold mb-4">Truy cập nhanh</h3>
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {quickActions.map((action, index) => (
            <QuickActionCard
              key={index}
              title={action.title}
              description={action.description}
              icon={action.icon}
              href={action.href}
              color={action.color}
            />
          ))}
        </div>
      </div>
      
      <div>
        <h3 className="text-xl font-semibold mb-4">Thông báo gần đây</h3>
        <Card>
          <CardContent className="p-6">
            <div className="space-y-4">
              <div className="flex items-start gap-4 pb-4 border-b">
                <div className="bg-blue-100 p-2 rounded-full">
                  <CalendarRange className="h-4 w-4 text-blue-600" />
                </div>
                <div>
                  <p className="font-medium">Đăng ký học phần học kỳ 2 năm học 2023-2024</p>
                  <p className="text-sm text-muted-foreground">Thời gian đăng ký: 15/01/2024 - 25/01/2024</p>
                  <p className="text-xs text-muted-foreground mt-1">2 ngày trước</p>
                </div>
              </div>
              
              <div className="flex items-start gap-4 pb-4 border-b">
                <div className="bg-amber-100 p-2 rounded-full">
                  <FileText className="h-4 w-4 text-amber-600" />
                </div>
                <div>
                  <p className="font-medium">Đã cập nhật điểm môn Cơ sở dữ liệu phân tán</p>
                  <p className="text-sm text-muted-foreground">Giảng viên đã nhập điểm cuối kỳ</p>
                  <p className="text-xs text-muted-foreground mt-1">3 ngày trước</p>
                </div>
              </div>
              
              <div className="flex items-start gap-4">
                <div className="bg-red-100 p-2 rounded-full">
                  <DollarSign className="h-4 w-4 text-red-600" />
                </div>
                <div>
                  <p className="font-medium">Thông báo đóng học phí học kỳ 2 năm học 2023-2024</p>
                  <p className="text-sm text-muted-foreground">Hạn cuối: 28/02/2024</p>
                  <p className="text-xs text-muted-foreground mt-1">1 tuần trước</p>
                </div>
              </div>
            </div>
          </CardContent>
          <CardFooter>
            <Button variant="ghost" className="w-full">Xem tất cả thông báo</Button>
          </CardFooter>
        </Card>
      </div>
    </div>
  );
} 