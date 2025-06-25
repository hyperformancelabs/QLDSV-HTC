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
import { DangKy, DangKyCancel, LopTinChi, UserRole } from '@/types';
import * as loptinchiService from '@/services/loptinchiService';
import { useAuthStore } from '@/store/use-auth-store';

export default function StudentRegistrationsPage() {
  const { toast } = useToast();
  const { user } = useAuthStore();
  const [registrations, setRegistrations] = useState<DangKy[]>([]);
  const [availableClasses, setAvailableClasses] = useState<LopTinChi[]>([]);
  const [loadingRegistrations, setLoadingRegistrations] = useState(true);
  const [loadingClasses, setLoadingClasses] = useState(true);
  const [selectedNienKhoa, setSelectedNienKhoa] = useState<string>('');
  const [selectedHocKy, setSelectedHocKy] = useState<number | undefined>(undefined);

  // Academic years for filtering
  const currentYear = new Date().getFullYear();
  const academicYears = Array.from({ length: 5 }, (_, i) => {
    const startYear = currentYear - 2 + i;
    return `${startYear}-${startYear + 1}`;
  });

  // Load student registrations
  useEffect(() => {
    if (user?.masv) {
      fetchStudentRegistrations(user.masv);
    }
  }, [user]);

  // Load available classes when filters change
  useEffect(() => {
    if (selectedNienKhoa || selectedHocKy !== undefined) {
      fetchAvailableClasses();
    }
  }, [selectedNienKhoa, selectedHocKy]);

  // Fetch student registrations
  const fetchStudentRegistrations = async (masv: string) => {
    setLoadingRegistrations(true);
    try {
      const data = await loptinchiService.getStudentRegistrations(masv);
      setRegistrations(data);
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

  // Fetch available classes for registration
  const fetchAvailableClasses = async () => {
    setLoadingClasses(true);
    try {
      const filters = {
        nienkhoa: selectedNienKhoa || undefined,
        hocky: selectedHocKy,
        only_available: true
      };
      const data = await loptinchiService.getLopTinChiList(filters);
      setAvailableClasses(data);
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

  // Format grade display
  const formatGrade = (grade: number | null) => {
    if (grade === null) return "-";
    return grade.toFixed(1);
  };

  // Check if student can register for a class
  const canRegister = (ltc: LopTinChi) => {
    // Check if already registered for this class
    return !registrations.some(reg => 
      reg.MALTC === ltc.MALTC && !reg.HUYDANGKY
    );
  };

  return (
    <div className="container mx-auto py-6">
      <h1 className="text-3xl font-bold mb-6">Đăng Ký Lớp Tín Chỉ</h1>
      
      {/* Student's current registrations */}
      <Card className="mb-8">
        <CardHeader>
          <CardTitle>Danh sách lớp tín chỉ đã đăng ký</CardTitle>
          <CardDescription>
            Các lớp tín chỉ bạn đã đăng ký và điểm số (nếu có)
          </CardDescription>
        </CardHeader>
        <CardContent>
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
                  <TableHead className="text-center">Điểm CC</TableHead>
                  <TableHead className="text-center">Điểm GK</TableHead>
                  <TableHead className="text-center">Điểm CK</TableHead>
                  <TableHead className="text-center">Điểm TK</TableHead>
                  <TableHead className="text-center">Trạng thái</TableHead>
                  <TableHead className="text-right">Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loadingRegistrations ? (
                  <TableRow>
                    <TableCell colSpan={12} className="text-center">
                      Đang tải dữ liệu...
                    </TableCell>
                  </TableRow>
                ) : registrations.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={12} className="text-center">
                      Bạn chưa đăng ký lớp tín chỉ nào
                    </TableCell>
                  </TableRow>
                ) : (
                  registrations.map((reg) => (
                    <TableRow key={reg.MALTC}>
                      <TableCell className="font-medium">{reg.MALTC}</TableCell>
                      <TableCell>{reg.NIENKHOA}</TableCell>
                      <TableCell>{reg.HOCKY}</TableCell>
                      <TableCell>{reg.TENMH}</TableCell>
                      <TableCell>{reg.NHOM}</TableCell>
                      <TableCell>{reg.HOTENGV}</TableCell>
                      <TableCell className="text-center">{formatGrade(reg.DIEM_CC)}</TableCell>
                      <TableCell className="text-center">{formatGrade(reg.DIEM_GK)}</TableCell>
                      <TableCell className="text-center">{formatGrade(reg.DIEM_CK)}</TableCell>
                      <TableCell className="text-center">{formatGrade(reg.DIEM_HET_MON)}</TableCell>
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
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>
      
      {/* Available classes for registration */}
      <Card>
        <CardHeader>
          <CardTitle>Đăng ký lớp tín chỉ mới</CardTitle>
          <CardDescription>
            Chọn niên khóa và học kỳ để xem danh sách lớp tín chỉ có thể đăng ký
          </CardDescription>
        </CardHeader>
        <CardContent>
          {/* Filters */}
          <div className="flex flex-wrap gap-4 mb-4">
            <div className="w-full md:w-1/4">
              <label className="text-sm font-medium mb-1 block">Niên khóa</label>
              <Select
                value={selectedNienKhoa || undefined}
                onValueChange={(value) => setSelectedNienKhoa(value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Chọn niên khóa" />
                </SelectTrigger>
                <SelectContent>
                  {academicYears.map(year => (
                    <SelectItem key={year} value={year}>{year}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div className="w-full md:w-1/4">
              <label className="text-sm font-medium mb-1 block">Học kỳ</label>
              <Select
                value={selectedHocKy?.toString() || undefined}
                onValueChange={(value) => setSelectedHocKy(value ? parseInt(value) : undefined)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Chọn học kỳ" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="1">Học kỳ 1</SelectItem>
                  <SelectItem value="2">Học kỳ 2</SelectItem>
                  <SelectItem value="3">Học kỳ 3</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <div className="w-full md:w-1/4 flex items-end">
              <Button onClick={fetchAvailableClasses}>
                Tìm lớp tín chỉ
              </Button>
            </div>
          </div>
          
          {/* Available classes table */}
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
                  <TableHead>Khoa</TableHead>
                  <TableHead className="text-center">SV tối thiểu</TableHead>
                  <TableHead className="text-center">SV đăng ký</TableHead>
                  <TableHead className="text-right">Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {!selectedNienKhoa && selectedHocKy === undefined ? (
                  <TableRow>
                    <TableCell colSpan={10} className="text-center">
                      Vui lòng chọn niên khóa và học kỳ để xem danh sách lớp tín chỉ
                    </TableCell>
                  </TableRow>
                ) : loadingClasses ? (
                  <TableRow>
                    <TableCell colSpan={10} className="text-center">
                      Đang tải dữ liệu...
                    </TableCell>
                  </TableRow>
                ) : availableClasses.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={10} className="text-center">
                      Không có lớp tín chỉ nào phù hợp với tiêu chí tìm kiếm
                    </TableCell>
                  </TableRow>
                ) : (
                  availableClasses.map((ltc) => (
                    <TableRow key={ltc.MALTC}>
                      <TableCell className="font-medium">{ltc.MALTC}</TableCell>
                      <TableCell>{ltc.NIENKHOA}</TableCell>
                      <TableCell>{ltc.HOCKY}</TableCell>
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
    </div>
  );
} 