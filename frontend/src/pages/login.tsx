import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { GraduationCap, User, Users, EyeIcon, EyeOffIcon, LogIn } from 'lucide-react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { useAuthStore } from '@/store/use-auth-store';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { toast } from '@/components/ui/use-toast';
import * as authService from '@/services/authService';
import { UserRole } from '@/types';

const loginSchema = z.object({
  username: z.string().min(1, 'Tên đăng nhập là bắt buộc'),
  password: z.string().min(1, 'Mật khẩu là bắt buộc'),
});

type LoginFormValues = z.infer<typeof loginSchema>;
type LoginTab = 'student' | 'teacher';

// Key for storing the active tab in localStorage
const ACTIVE_TAB_KEY = 'qldsv_login_active_tab';

export default function LoginPage() {
  // Get the saved tab from localStorage or default to 'teacher'
  const getSavedTab = (): LoginTab => {
    const savedTab = localStorage.getItem(ACTIVE_TAB_KEY);
    return (savedTab === 'student' || savedTab === 'teacher') ? savedTab as LoginTab : 'teacher';
  };
  
  const [showPassword, setShowPassword] = useState(false);
  const [activeTab, setActiveTab] = useState<LoginTab>(getSavedTab());
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();
  const { login } = useAuthStore();
  
  const { register, handleSubmit, reset, formState: { errors } } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      username: '',
      password: '',
    },
  });

  // Save the active tab to localStorage when it changes
  const handleTabChange = (value: string) => {
    const tab = value as LoginTab;
    setActiveTab(tab);
    localStorage.setItem(ACTIVE_TAB_KEY, tab);

    // Xóa dữ liệu form khi chuyển tab tránh autofill sai
    reset({ username: '', password: '' });
  };

  const onSubmit = async (data: LoginFormValues) => {
    setIsLoading(true);
    
    try {
      const user = await authService.login(data);
      
      // Kiểm tra xem tab hiện tại có phù hợp với role trả về không
      const isStudentTab = activeTab === 'student';
      const isStudentRole = user.role === UserRole.SV;

      if (isStudentTab !== isStudentRole) {
        toast.error({
          title: 'Sai loại tài khoản',
          description: isStudentTab
            ? 'Vui lòng đăng nhập bằng tài khoản sinh viên.'
            : 'Vui lòng đăng nhập bằng tài khoản giảng viên.',
        });
        return;
      }

      login(user);
      
      toast.success({
        title: 'Đăng nhập thành công',
        description: 'Chào mừng bạn quay trở lại!',
      });
      
      navigate('/dashboard');
    } catch (error) {
      toast.error({
        title: 'Đăng nhập thất bại',
        description: 'Tên đăng nhập hoặc mật khẩu không chính xác',
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen login-bg flex items-center justify-center p-4 sm:p-6 md:p-8">
      <div className="w-full max-w-md space-y-8">
        {/* Logo and Title */}
        <div className="flex flex-col items-center text-center">
          <div className="bg-primary rounded-full p-3 mb-4">
            <GraduationCap className="h-10 w-10 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-white">HỆ THỐNG QUẢN LÝ ĐIỂM SINH VIÊN</h1>
          <p className="text-lg text-white/80 font-medium">HỆ TÍN CHỈ</p>
        </div>
        
        <Card className="shadow-xl">
          <CardHeader className="space-y-1">
            <CardTitle className="text-xl text-center">Đăng nhập</CardTitle>
            <CardDescription className="text-center">
              Nhập thông tin đăng nhập để truy cập hệ thống
            </CardDescription>
          </CardHeader>
          
          <Tabs defaultValue={activeTab} value={activeTab} onValueChange={handleTabChange}>
            <TabsList className="grid grid-cols-2 mx-6">
              <TabsTrigger value="teacher" className="flex items-center gap-2">
                <Users className="h-4 w-4" />
                <span>Giảng viên</span>
              </TabsTrigger>
              <TabsTrigger value="student" className="flex items-center gap-2">
                <User className="h-4 w-4" />
                <span>Sinh viên</span>
              </TabsTrigger>
            </TabsList>
            
            <CardContent className="pt-6">
              <form onSubmit={handleSubmit(onSubmit)} autoComplete="off" className="space-y-4">
                <div className="space-y-2">
                  <label htmlFor="username" className="text-sm font-medium">
                    {activeTab === 'student' ? 'Mã sinh viên' : 'Tài khoản'}
                  </label>
                  <Input
                    id="username"
                    placeholder={activeTab === 'student' ? 'Nhập mã sinh viên' : 'Nhập tài khoản'}
                    autoComplete="new-username"
                    autoCapitalize="none"
                    {...register('username')}
                  />
                  {errors.username && (
                    <p className="text-sm text-destructive">{errors.username.message}</p>
                  )}
                </div>
                
                <div className="space-y-2">
                  <label htmlFor="password" className="text-sm font-medium">
                    Mật khẩu
                  </label>
                  <div className="relative">
                    <Input
                      id="password"
                      type={showPassword ? 'text' : 'password'}
                      placeholder="Nhập mật khẩu"
                      autoComplete="new-password"
                      {...register('password')}
                    />
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon"
                      className="absolute right-0 top-0 h-full px-3"
                      onClick={() => setShowPassword(!showPassword)}
                    >
                      {showPassword ? (
                        <EyeOffIcon className="h-4 w-4" />
                      ) : (
                        <EyeIcon className="h-4 w-4" />
                      )}
                      <span className="sr-only">
                        {showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu'}
                      </span>
                    </Button>
                  </div>
                  {errors.password && (
                    <p className="text-sm text-destructive">{errors.password.message}</p>
                  )}
                </div>
                
                <Button type="submit" className="w-full" disabled={isLoading}>
                  {isLoading ? (
                    <div className="flex items-center">
                      <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                      </svg>
                      Đang đăng nhập...
                    </div>
                  ) : (
                    <div className="flex items-center">
                      <LogIn className="mr-2 h-4 w-4" />
                      Đăng nhập
                    </div>
                  )}
                </Button>
              </form>
            </CardContent>
          </Tabs>
          
          <CardFooter className="flex flex-col">
            <div className="bg-muted rounded-md p-3 text-sm w-full">
              <p className="font-medium mb-2">Tài khoản mẫu:</p>
              <div className="space-y-1 text-muted-foreground">
                <p><strong>PGV:</strong> GV001_LOGIN / 123456</p>
                <p><strong>Khoa:</strong> GV002_LOGIN / 123456</p>
                <p><strong>SV:</strong> N21DCCN001 / 123456</p>
              </div>
            </div>
          </CardFooter>
        </Card>
        
        <div className="text-center text-sm text-white/70">
          <p>© {new Date().getFullYear()} QLDSV-HTC. All rights reserved.</p>
        </div>
      </div>
    </div>
  );
} 