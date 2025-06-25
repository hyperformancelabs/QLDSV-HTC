import { useState, useEffect } from 'react';
import { useToast } from '@/components/ui/use-toast';
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { 
  Select, 
  SelectContent, 
  SelectItem, 
  SelectTrigger, 
  SelectValue 
} from '@/components/ui/select';
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from '@/components/ui/tabs';
import { DangKy, DangKyCancel, LopTinChi, UserRole } from '@/types';
import * as loptinchiService from '@/services/loptinchiService';
import { useAuthStore } from '@/store/use-auth-store';
import { getCurrentAcademicYear, getCurrentSemester, getAcademicYearOptions, isSemesterInPast } from '@/utils/academic-helpers';

export default function StudentRegistrationsPage() {
  const { toast } = useToast();
  const { user } = useAuthStore();
  const [registrations, setRegistrations] = useState<DangKy[]>([]);
  const [availableClasses, setAvailableClasses] = useState<LopTinChi[]>([]);
  const [loadingRegistrations, setLoadingRegistrations] = useState(true);
  const [loadingClasses, setLoadingClasses] = useState(true);
  const [activeTab, setActiveTab] = useState<string>("current");
  
  // Historical registrations
  const [historicalRegistrations, setHistoricalRegistrations] = useState<DangKy[]>([]);
  const [loadingHistorical, setLoadingHistorical] = useState(false);

  // Current semester and year for filtering
  const currentSemester = getCurrentSemester();
  const currentAcademicYear = getCurrentAcademicYear();

  // Load student registrations
  useEffect(() => {
    if (user?.masv) {
      fetchStudentRegistrations(user.masv);
    }
  }, [user]);

  // Load available classes for current semester on initial load
  useEffect(() => {
    if (user?.masv) {
      fetchAvailableClasses();
    }
  }, [user]);

  // Fetch student registrations
  const fetchStudentRegistrations = async (masv: string) => {
    setLoadingRegistrations(true);
    try {
      const data = await loptinchiService.getStudentRegistrations(masv);
      
      // Split registrations into current and historical
      const current: DangKy[] = [];
      const historical: DangKy[] = [];
      
      data.forEach(reg => {
        if (isSemesterInPast(reg.NIENKHOA, reg.HOCKY)) {
          historical.push(reg);
        } else {
          current.push(reg);
        }
      });
      
      setRegistrations(current);
      setHistoricalRegistrations(historical);
    } catch (error) {
      toast({
        title: "Lỗi",
        description: error instanceof Error ? error.message : "Không thể lấy danh sách đăng ký",
        variant: "destructive",
      });
    } finally {
      setLoadingRegistrations(false);
    }
  };

  // Fetch available classes for registration - always for current semester only
  const fetchAvailableClasses = async () => {
    setLoadingClasses(true);
    try {
      const filters = {
        nienkhoa: currentAcademicYear,
        hocky: currentSemester,
        only_available: true
      };
      const data = await loptinchiService.getLopTinChiList(filters);
      
      // Filter on frontend to ensure only current semester classes are shown
      // and only classes that are open (HUYLOP = 0)
      const availableOpenClasses = data.filter(
        ltc => ltc.NIENKHOA === currentAcademicYear && 
               ltc.HOCKY === currentSemester &&
               ltc.HUYLOP === false
      );
      
      setAvailableClasses(availableOpenClasses);
    } catch (error) {
      toast({
        title: "Lỗi",
        description: error instanceof Error ? error.message : "Không thể lấy danh sách lớp tín chỉ",
        variant: "destructive",
      });
    } finally {
      setLoadingClasses(false);
    }
  };

  // Register for a class
  const handleRegister = async (maltc: number) => {
    if (!user?.masv) return;
    
    // Check if this is a re-registration (student previously canceled this class)
    const existingRegistration = registrations.find(reg => reg.MALTC === maltc);
    
    if (existingRegistration && existingRegistration.HUYDANGKY) {
      // This is a re-registration
      return handleReregister(maltc);
    }
    
    // This is a new registration
    try {
      await loptinchiService.registerCourse({
        MALTC: maltc,
        MASV: user.masv
      });
      
      toast({
        title: "Thành công",
        description: "Đăng ký lớp tín chỉ thành công",
      });
      
      // Refresh both lists
      fetchStudentRegistrations(user.masv);
      fetchAvailableClasses();
    } catch (error) {
      toast({
        title: "Lỗi",
        description: error instanceof Error ? error.message : "Không thể đăng ký lớp tín chỉ",
        variant: "destructive",
      });
    }
  };

  // Cancel registration
  const handleCancelRegistration = async (maltc: number) => {
    if (!user?.masv) return;
    if (!confirm("Bạn có chắc chắn muốn hủy đăng ký lớp tín chỉ này?")) return;
    
    try {
      await loptinchiService.cancelRegistration({
        MALTC: maltc,
        MASV: user.masv
      });
      
      toast({
        title: "Thành công",
        description: "Hủy đăng ký lớp tín chỉ thành công",
      });
      
      // Refresh both lists
      fetchStudentRegistrations(user.masv);
      fetchAvailableClasses();
    } catch (error) {
      toast({
        title: "Lỗi",
        description: error instanceof Error ? error.message : "Không thể hủy đăng ký lớp tín chỉ",
        variant: "destructive",
      });
    }
  };

  // Handle re-registration of a previously canceled course
  const handleReregister = async (maltc: number) => {
    if (!user?.masv) return;
    
    try {
      await loptinchiService.reregisterCourse({
        MALTC: maltc,
        MASV: user.masv
      });
      
      toast({
        title: "Thành công",
        description: "Đăng ký lại lớp tín chỉ thành công",
      });
      
      // Refresh both lists
      fetchStudentRegistrations(user.masv);
      fetchAvailableClasses();
    } catch (error) {
      toast({
        title: "Lỗi",
        description: error instanceof Error ? error.message : "Không thể đăng ký lại lớp tín chỉ",
        variant: "destructive",
      });
    }
  };

  // Format grade display
  const formatGrade = (grade: number | null) => {
    if (grade === null) return "-";
    return grade.toFixed(1);
  };

  // Check if student can register for a class
  const canRegister = (ltc: LopTinChi) => {
    // Check if already registered for this class and registration is active
    const existingRegistration = registrations.find(reg => reg.MALTC === ltc.MALTC);
    
    // Allow registration if:
    // 1. No registration exists for this class, or
    // 2. Existing registration was canceled (HUYDANGKY = true)
    return !existingRegistration || existingRegistration.HUYDANGKY;
  };

  // Render current semester registration table
  const renderCurrentRegistrationTable = (data: DangKy[]) => (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead className="w-[80px]">Mã LTC</TableHead>
            <TableHead>Niên khóa</TableHead>
            <TableHead>Học kỳ</TableHead>
            <TableHead>Môn học</TableHead>
            <TableHead>Nhóm</TableHead>
            <TableHead>Giảng viên</TableHead>
            <TableHead className="text-center">Trạng thái</TableHead>
            <TableHead className="text-right">Thao tác</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {data.length === 0 ? (
            <TableRow>
              <TableCell colSpan={8} className="text-center">
                Bạn chưa đăng ký lớp tín chỉ nào trong học kỳ hiện tại
              </TableCell>
            </TableRow>
          ) : (
            data.map((reg) => (
              <TableRow key={reg.MALTC}>
                <TableCell className="font-medium">{reg.MALTC}</TableCell>
                <TableCell>{reg.NIENKHOA}</TableCell>
                <TableCell>{reg.HOCKY}</TableCell>
                <TableCell>{reg.TENMH}</TableCell>
                <TableCell>{reg.NHOM}</TableCell>
                <TableCell>{reg.HOTENGV}</TableCell>
                <TableCell className="text-center">
                  {reg.HUYDANGKY ? (
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                      Đã hủy
                    </span>
                  ) : (
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      Đã đăng ký
                    </span>
                  )}
                </TableCell>
                <TableCell className="text-right">
                  {!reg.HUYDANGKY && reg.DIEM_CC === null && (
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleCancelRegistration(reg.MALTC)}
                      className="text-red-500 hover:text-red-700"
                    >
                      Hủy đăng ký
                    </Button>
                  )}
                  {reg.HUYDANGKY && (
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleReregister(reg.MALTC)}
                      className="text-blue-500 hover:text-blue-700"
                    >
                      Đăng ký lại
                    </Button>
                  )}
                </TableCell>
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>
    </div>
  );

  // Render historical registration table (without grades)
  const renderHistoricalRegistrationTable = (data: DangKy[]) => (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead className="w-[80px]">Mã LTC</TableHead>
            <TableHead>Niên khóa</TableHead>
            <TableHead>Học kỳ</TableHead>
            <TableHead>Môn học</TableHead>
            <TableHead>Nhóm</TableHead>
            <TableHead>Giảng viên</TableHead>
            <TableHead className="text-center">Trạng thái</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {data.length === 0 ? (
            <TableRow>
              <TableCell colSpan={7} className="text-center">
                Không có dữ liệu lịch sử đăng ký
              </TableCell>
            </TableRow>
          ) : (
            data.map((reg) => (
              <TableRow key={reg.MALTC}>
                <TableCell className="font-medium">{reg.MALTC}</TableCell>
                <TableCell>{reg.NIENKHOA}</TableCell>
                <TableCell>{reg.HOCKY}</TableCell>
                <TableCell>{reg.TENMH}</TableCell>
                <TableCell>{reg.NHOM}</TableCell>
                <TableCell>{reg.HOTENGV}</TableCell>
                <TableCell className="text-center">
                  {reg.HUYDANGKY ? (
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                      Đã hủy
                    </span>
                  ) : (
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      Đã đăng ký
                    </span>
                  )}
                </TableCell>
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>
    </div>
  );

  return (
    <div className="container mx-auto py-6">
      <h1 className="text-3xl font-bold mb-6">Đăng Ký Lớp Tín Chỉ</h1>
      
      {/* Available classes for registration - MOVED TO TOP */}
      <Card className="mb-8">
        <CardHeader>
          <CardTitle>Đăng ký lớp tín chỉ học kỳ hiện tại</CardTitle>
          <CardDescription>
            Danh sách lớp tín chỉ đang mở có thể đăng ký trong học kỳ {currentSemester}, niên khóa {currentAcademicYear}
            <span className="ml-2 text-xs text-amber-600">
              (Đang hiển thị: {availableClasses.length} lớp)
            </span>
          </CardDescription>
        </CardHeader>
        <CardContent>
          {/* Available classes table */}
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-[80px]">Mã LTC</TableHead>
                  <TableHead>Môn học</TableHead>
                  <TableHead>Nhóm</TableHead>
                  <TableHead>Giảng viên</TableHead>
                  <TableHead>Khoa</TableHead>
                  <TableHead className="text-center">SV tối thiểu</TableHead>
                  <TableHead className="text-center">SV đăng ký</TableHead>
                  <TableHead className="text-right">Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loadingClasses ? (
                  <TableRow>
                    <TableCell colSpan={8} className="text-center">
                      Đang tải dữ liệu...
                    </TableCell>
                  </TableRow>
                ) : availableClasses.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={8} className="text-center">
                      Không có lớp tín chỉ nào được mở trong học kỳ hiện tại
                    </TableCell>
                  </TableRow>
                ) : (
                  availableClasses.map((ltc) => (
                    <TableRow key={ltc.MALTC}>
                      <TableCell className="font-medium">{ltc.MALTC}</TableCell>
                      <TableCell>
                        <div className="font-medium">{ltc.TENMH}</div>
                        <div className="text-xs text-muted-foreground">{ltc.MAMH}</div>
                      </TableCell>
                      <TableCell>{ltc.NHOM}</TableCell>
                      <TableCell>{ltc.HOTENGV}</TableCell>
                      <TableCell>{ltc.TENKHOA}</TableCell>
                      <TableCell className="text-center">{ltc.SOSVTOITHIEU}</TableCell>
                      <TableCell className="text-center">{ltc.SOSVDANGKY}</TableCell>
                      <TableCell className="text-right">
                        {canRegister(ltc) ? (
                          <Button
                            size="sm"
                            onClick={() => handleRegister(ltc.MALTC)}
                          >
                            Đăng ký
                          </Button>
                        ) : (
                          <Button
                            size="sm"
                            disabled
                          >
                            Đã đăng ký
                          </Button>
                        )}
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>
      
      {/* Student's registrations tabs */}
      <Card>
        <CardHeader>
          <CardTitle>Danh sách lớp tín chỉ đã đăng ký</CardTitle>
          <CardDescription>
            Quản lý các lớp tín chỉ bạn đã đăng ký
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs defaultValue="current" onValueChange={setActiveTab}>
            <TabsList className="mb-4">
              <TabsTrigger value="current">Học kỳ hiện tại</TabsTrigger>
              <TabsTrigger value="history">Lịch sử đăng ký</TabsTrigger>
            </TabsList>
            
            <TabsContent value="current">
              {loadingRegistrations ? (
                <div className="flex justify-center py-4">
                  <div>Đang tải dữ liệu...</div>
                </div>
              ) : (
                renderCurrentRegistrationTable(registrations)
              )}
              <div className="mt-4 text-sm text-muted-foreground">
                <p>* Để xem điểm số của các học kỳ trước, vui lòng truy cập trang "Quản lý điểm".</p>
              </div>
            </TabsContent>
            
            <TabsContent value="history">
              {loadingRegistrations ? (
                <div className="flex justify-center py-4">
                  <div>Đang tải dữ liệu...</div>
                </div>
              ) : (
                renderHistoricalRegistrationTable(historicalRegistrations)
              )}
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>
    </div>
  );
} 