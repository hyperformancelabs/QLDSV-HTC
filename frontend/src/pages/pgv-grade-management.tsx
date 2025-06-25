import { useState, useEffect } from 'react';
import { useToast } from '@/components/ui/use-toast';
import { 
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
  CardFooter
} from "@/components/ui/card";
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from '@/components/ui/table';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Separator } from '@/components/ui/separator';
import { AlertCircle, Save, Search } from 'lucide-react';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import * as loptinchiService from '@/services/loptinchiService';
import { StudentGradeResponse, StudentGrade } from '@/types';
import { useAuthStore } from '@/store/use-auth-store';

export default function PGVGradeManagementPage() {
  const { toast } = useToast();
  const { user } = useAuthStore();
  const [isLoading, setIsLoading] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  
  // Search filters
  const [nienkhoa, setNienkhoa] = useState<string>('');
  const [hocky, setHocky] = useState<string>('');
  const [mamh, setMamh] = useState<string>('');
  const [nhom, setNhom] = useState<string>('');
  
  // Data
  const [students, setStudents] = useState<StudentGradeResponse[]>([]);
  const [editedGrades, setEditedGrades] = useState<Record<string, StudentGrade>>({});
  const [hasChanges, setHasChanges] = useState(false);
  
  // Academic years options (last 5 years)
  const nienKhoaOptions = () => {
    const currentYear = new Date().getFullYear();
    const options = [];
    for (let i = 0; i < 5; i++) {
      const startYear = currentYear - i;
      const endYear = startYear + 1;
      options.push(`${startYear}-${endYear}`);
    }
    return options;
  };

  // Search for students to grade
  const handleSearch = async () => {
    // Validate inputs
    if (!nienkhoa || !hocky || !mamh || !nhom) {
      toast({
        title: "Thiếu thông tin",
        description: "Vui lòng nhập đầy đủ thông tin tìm kiếm",
        variant: "destructive",
      });
      return;
    }

    setIsLoading(true);
    try {
      const data = await loptinchiService.getStudentsForGrading(
        nienkhoa,
        parseInt(hocky),
        mamh,
        parseInt(nhom)
      );
      
      setStudents(data);
      
      // Reset edited grades
      setEditedGrades({});
      setHasChanges(false);
    } catch (error) {
      toast({
        title: "Lỗi",
        description: error instanceof Error ? error.message : "Không thể lấy danh sách sinh viên",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  // Handle grade input change
  const handleGradeChange = (masv: string, field: 'DIEM_CC' | 'DIEM_GK' | 'DIEM_CK', value: string) => {
    // Xử lý giá trị đầu vào
    let numValue: number | null = null;
    
    // Nếu chuỗi không rỗng, chuyển đổi thành số
    if (value.trim() !== '') {
      numValue = parseFloat(value);
      
      // Kiểm tra giá trị có hợp lệ không
      if (isNaN(numValue)) {
        numValue = null;
      } else {
        // Đảm bảo giá trị nằm trong khoảng 0-10
        numValue = Math.max(0, Math.min(10, numValue));
        
        // Đối với GK và CK, làm tròn đến 0.5 gần nhất
        if (field !== 'DIEM_CC') {
          numValue = Math.round(numValue * 2) / 2;
        } else {
          // Điểm CC phải là số nguyên
          numValue = Math.round(numValue);
        }
      }
    }
    
    // Tìm sinh viên
    const student = students.find(s => s.MASV === masv);
    if (!student) return;
    
    // Cập nhật điểm đã chỉnh sửa
    setEditedGrades(prev => {
      const updatedGrades = { ...prev };
      
      if (!updatedGrades[masv]) {
        // Nếu chưa có dữ liệu chỉnh sửa cho sinh viên này, 
        // khởi tạo với dữ liệu hiện có từ server
        updatedGrades[masv] = {
          MASV: masv,
          MALTC: student.MALTC,
          DIEM_CC: student.DIEM_CC,
          DIEM_GK: student.DIEM_GK,
          DIEM_CK: student.DIEM_CK
        };
      }
      
      // Chỉ cập nhật trường đang được chỉnh sửa, giữ nguyên các trường khác
      if (field === 'DIEM_CC') updatedGrades[masv].DIEM_CC = numValue;
      if (field === 'DIEM_GK') updatedGrades[masv].DIEM_GK = numValue;
      if (field === 'DIEM_CK') updatedGrades[masv].DIEM_CK = numValue;
      
      return updatedGrades;
    });
    
    setHasChanges(true);
  };

  // Save all edited grades
  const handleSaveAllGrades = async () => {
    if (!students.length || !Object.keys(editedGrades).length) return;
    
    setIsSaving(true);
    try {
      // Get the MALTC from the first student
      const maltc = students[0].MALTC;
      
      // Convert edited grades to array
      const gradesToSave = Object.values(editedGrades);
      
      await loptinchiService.saveMultipleGrades(maltc, gradesToSave);
      
      toast({
        title: "Thành công",
        description: "Đã lưu điểm cho tất cả sinh viên",
      });
      
      // Refresh data
      handleSearch();
    } catch (error) {
      toast({
        title: "Lỗi",
        description: error instanceof Error ? error.message : "Không thể lưu điểm",
        variant: "destructive",
      });
    } finally {
      setIsSaving(false);
    }
  };

  // Calculate final grade
  const calculateFinalGrade = (cc: number | null, gk: number | null, ck: number | null): string => {
    if (cc === null || gk === null || ck === null) return "-";
    const finalGrade = cc * 0.1 + gk * 0.3 + ck * 0.6;
    return finalGrade.toFixed(1);
  };

  // Get current grade (from either edited state or original data)
  const getCurrentGrade = (student: StudentGradeResponse, field: 'DIEM_CC' | 'DIEM_GK' | 'DIEM_CK'): string => {
    const editedStudent = editedGrades[student.MASV];
    
    if (editedStudent && field in editedStudent) {
      const value = editedStudent[field];
      return value !== null && value !== undefined ? value.toString() : '';
    }
    
    return student[field] !== null ? student[field]!.toString() : '';
  };

  return (
    <div className="container mx-auto py-6">
      <h1 className="text-3xl font-bold mb-6">Quản Lý Điểm Sinh Viên</h1>
      
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Tìm kiếm lớp để nhập điểm</CardTitle>
          <CardDescription>
            Nhập thông tin lớp tín chỉ để xem danh sách sinh viên và nhập điểm
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            <div className="space-y-2">
              <Label htmlFor="nienkhoa">Niên khóa</Label>
              <Select value={nienkhoa} onValueChange={setNienkhoa}>
                <SelectTrigger id="nienkhoa">
                  <SelectValue placeholder="Chọn niên khóa" />
                </SelectTrigger>
                <SelectContent>
                  {nienKhoaOptions().map(option => (
                    <SelectItem key={option} value={option}>{option}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="hocky">Học kỳ</Label>
              <Select value={hocky} onValueChange={setHocky}>
                <SelectTrigger id="hocky">
                  <SelectValue placeholder="Chọn học kỳ" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="1">Học kỳ 1</SelectItem>
                  <SelectItem value="2">Học kỳ 2</SelectItem>
                  <SelectItem value="3">Học kỳ 3</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="mamh">Mã môn học</Label>
              <Input 
                id="mamh" 
                placeholder="Nhập mã môn học" 
                value={mamh} 
                onChange={e => setMamh(e.target.value)} 
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="nhom">Nhóm</Label>
              <Input 
                id="nhom" 
                placeholder="Nhập số nhóm" 
                type="number" 
                min="1" 
                value={nhom} 
                onChange={e => setNhom(e.target.value)} 
              />
            </div>
            
            <div className="flex items-end">
              <Button 
                onClick={handleSearch} 
                disabled={isLoading}
                className="w-full"
              >
                <Search className="mr-2 h-4 w-4" />
                Tìm kiếm
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
      
      {students.length > 0 && (
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <div>
              <CardTitle>Danh sách sinh viên</CardTitle>
              <CardDescription>
                Nhập điểm cho {students.length} sinh viên
              </CardDescription>
            </div>
            <Button 
              onClick={handleSaveAllGrades} 
              disabled={isSaving || !hasChanges}
              variant="default"
            >
              <Save className="mr-2 h-4 w-4" />
              Lưu tất cả
            </Button>
          </CardHeader>
          <CardContent>
            <div className="rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-[80px]">MSSV</TableHead>
                    <TableHead>Họ và tên</TableHead>
                    <TableHead className="w-[120px] text-center">Điểm CC (10%)</TableHead>
                    <TableHead className="w-[120px] text-center">Điểm GK (30%)</TableHead>
                    <TableHead className="w-[120px] text-center">Điểm CK (60%)</TableHead>
                    <TableHead className="w-[120px] text-center">Điểm TK</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {students.map((student) => {
                    // Calculate current final grade based on potentially edited values
                    const cc = editedGrades[student.MASV]?.DIEM_CC ?? student.DIEM_CC;
                    const gk = editedGrades[student.MASV]?.DIEM_GK ?? student.DIEM_GK;
                    const ck = editedGrades[student.MASV]?.DIEM_CK ?? student.DIEM_CK;
                    const finalGrade = calculateFinalGrade(cc, gk, ck);
                    
                    return (
                      <TableRow key={student.MASV}>
                        <TableCell className="font-medium">{student.MASV}</TableCell>
                        <TableCell>{student.HO} {student.TEN}</TableCell>
                        <TableCell>
                          <Input 
                            type="number" 
                            min="0" 
                            max="10" 
                            step="1"
                            value={getCurrentGrade(student, 'DIEM_CC')} 
                            onChange={(e) => handleGradeChange(student.MASV, 'DIEM_CC', e.target.value)}
                            className="text-center"
                          />
                        </TableCell>
                        <TableCell>
                          <Input 
                            type="number" 
                            min="0" 
                            max="10" 
                            step="0.5"
                            value={getCurrentGrade(student, 'DIEM_GK')} 
                            onChange={(e) => handleGradeChange(student.MASV, 'DIEM_GK', e.target.value)}
                            className="text-center"
                          />
                        </TableCell>
                        <TableCell>
                          <Input 
                            type="number" 
                            min="0" 
                            max="10" 
                            step="0.5"
                            value={getCurrentGrade(student, 'DIEM_CK')} 
                            onChange={(e) => handleGradeChange(student.MASV, 'DIEM_CK', e.target.value)}
                            className="text-center"
                          />
                        </TableCell>
                        <TableCell className="text-center font-medium">{finalGrade}</TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </div>
          </CardContent>
          <CardFooter className="flex justify-between">
            <p className="text-sm text-muted-foreground">
              Điểm CC: 0-10 (số nguyên), Điểm GK/CK: 0-10 (làm tròn 0.5)
            </p>
            <Button 
              onClick={handleSaveAllGrades} 
              disabled={isSaving || !hasChanges}
              variant="default"
            >
              <Save className="mr-2 h-4 w-4" />
              Lưu tất cả
            </Button>
          </CardFooter>
        </Card>
      )}
      
      {isLoading && (
        <div className="flex justify-center py-8">
          <div>Đang tải dữ liệu...</div>
        </div>
      )}
      
      {!isLoading && students.length === 0 && (
        <Alert>
          <AlertCircle className="h-4 w-4" />
          <AlertTitle>Chưa có dữ liệu</AlertTitle>
          <AlertDescription>
            Vui lòng nhập thông tin tìm kiếm và nhấn nút "Tìm kiếm" để xem danh sách sinh viên cần nhập điểm.
          </AlertDescription>
        </Alert>
      )}
    </div>
  );
} 