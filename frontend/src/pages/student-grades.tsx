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
  SelectValue,
} from "@/components/ui/select";
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { AlertCircle, FileDown } from 'lucide-react';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { DangKy } from '@/types';
import * as loptinchiService from '@/services/loptinchiService';
import { useAuthStore } from '@/store/use-auth-store';

// Interface for grouped registrations
interface SemesterGroup {
  nienkhoa: string;
  hocky: number;
  registrations: DangKy[];
}

export default function StudentGradesPage() {
  const { toast } = useToast();
  const { user } = useAuthStore();
  const [semesterGroups, setSemesterGroups] = useState<SemesterGroup[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedSemester, setSelectedSemester] = useState<string>('all');

  // Load student registrations with grades
  useEffect(() => {
    if (user?.masv) {
      fetchStudentGrades(user.masv);
    }
  }, [user]);

  // Fetch student grades
  const fetchStudentGrades = async (masv: string) => {
    setIsLoading(true);
    try {
      const data = await loptinchiService.getStudentRegistrations(masv);
      
      // Filter out registrations that have been canceled
      const validRegistrations = data.filter(reg => !reg.HUYDANGKY);
      
      // Group registrations by semester and academic year
      const groups: Record<string, SemesterGroup> = {};
      
      validRegistrations.forEach(reg => {
        const key = `${reg.NIENKHOA}_${reg.HOCKY}`;
        if (!groups[key]) {
          groups[key] = {
            nienkhoa: reg.NIENKHOA,
            hocky: reg.HOCKY,
            registrations: []
          };
        }
        groups[key].registrations.push(reg);
      });
      
      // Convert to array and sort by newest semester first
      const groupsArray = Object.values(groups).sort((a, b) => {
        // First compare by academic year (most recent first)
        const yearA = parseInt(a.nienkhoa.split('-')[0]);
        const yearB = parseInt(b.nienkhoa.split('-')[0]);
        if (yearB !== yearA) return yearB - yearA;
        
        // If same year, compare by semester (descending)
        return b.hocky - a.hocky;
      });
      
      setSemesterGroups(groupsArray);
    } catch (error) {
      toast({
        title: "Lỗi",
        description: error instanceof Error ? error.message : "Không thể lấy dữ liệu điểm",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  // Format grade display
  const formatGrade = (grade: number | null) => {
    if (grade === null) return "-";
    return grade.toFixed(1);
  };

  // Calculate GPA for a semester
  const calculateSemesterGPA = (registrations: DangKy[]) => {
    const validGrades = registrations.filter(reg => reg.DIEM_HET_MON !== null);
    if (validGrades.length === 0) return "-";
    
    const totalGradePoints = validGrades.reduce((sum, reg) => sum + (reg.DIEM_HET_MON || 0), 0);
    return (totalGradePoints / validGrades.length).toFixed(2);
  };

  // Calculate overall GPA across all semesters
  const calculateOverallGPA = () => {
    const allValidGrades = semesterGroups.flatMap(group => 
      group.registrations.filter(reg => reg.DIEM_HET_MON !== null)
    );
    
    if (allValidGrades.length === 0) return "-";
    
    const totalGradePoints = allValidGrades.reduce((sum, reg) => sum + (reg.DIEM_HET_MON || 0), 0);
    return (totalGradePoints / allValidGrades.length).toFixed(2);
  };

  // Get letter grade based on numeric grade
  const getLetterGrade = (grade: number | null): string => {
    if (grade === null) return "-";
    if (grade >= 9.0) return "A+";
    if (grade >= 8.5) return "A";
    if (grade >= 8.0) return "B+";
    if (grade >= 7.0) return "B";
    if (grade >= 6.5) return "C+";
    if (grade >= 5.5) return "C";
    if (grade >= 5.0) return "D+";
    if (grade >= 4.0) return "D";
    return "F";
  };

  // Get color for grade badge
  const getGradeColor = (grade: number | null): "default" | "secondary" | "destructive" | "outline" | "success" | "warning" => {
    if (grade === null) return "secondary";
    if (grade >= 8.0) return "success";
    if (grade >= 6.5) return "default";
    if (grade >= 4.0) return "warning";
    return "destructive";
  };

  // Filter semester groups based on selection
  const filteredGroups = selectedSemester === 'all' 
    ? semesterGroups 
    : semesterGroups.filter(group => `${group.nienkhoa}_${group.hocky}` === selectedSemester);

  return (
    <div className="container mx-auto py-6">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
        <h1 className="text-3xl font-bold">Bảng Điểm Sinh Viên</h1>
        
        <div className="flex items-center space-x-2 mt-4 md:mt-0">
          {user?.masv && (
            <div className="text-sm font-medium">
              MSSV: <span className="font-bold">{user.masv}</span>
            </div>
          )}
          
          <Badge variant="outline" className="ml-2">
            GPA: {calculateOverallGPA()}
          </Badge>
          
          <Button variant="outline" size="sm">
            <FileDown className="mr-2 h-4 w-4" />
            Xuất PDF
          </Button>
        </div>
      </div>
      
      {isLoading ? (
        <div className="flex justify-center py-8">
          <div>Đang tải dữ liệu điểm...</div>
        </div>
      ) : semesterGroups.length === 0 ? (
        <Alert>
          <AlertCircle className="h-4 w-4" />
          <AlertTitle>Chưa có dữ liệu điểm</AlertTitle>
          <AlertDescription>
            Hiện tại chưa có dữ liệu điểm nào được ghi nhận cho tài khoản của bạn.
          </AlertDescription>
        </Alert>
      ) : (
        <>
          <div className="mb-6">
            <Select value={selectedSemester} onValueChange={setSelectedSemester}>
              <SelectTrigger className="w-[280px]">
                <SelectValue placeholder="Chọn học kỳ" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Tất cả học kỳ</SelectItem>
                {semesterGroups.map(group => (
                  <SelectItem 
                    key={`${group.nienkhoa}_${group.hocky}`} 
                    value={`${group.nienkhoa}_${group.hocky}`}
                  >
                    Học kỳ {group.hocky}, niên khóa {group.nienkhoa}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          
          {filteredGroups.map((group) => (
            <Card key={`${group.nienkhoa}_${group.hocky}`} className="mb-6">
              <CardHeader className="pb-3">
                <div className="flex flex-col md:flex-row md:items-center md:justify-between">
                  <CardTitle>
                    Học kỳ {group.hocky}, niên khóa {group.nienkhoa}
                  </CardTitle>
                  <CardDescription className="md:text-right">
                    Điểm trung bình học kỳ: <Badge variant="outline">{calculateSemesterGPA(group.registrations)}</Badge>
                  </CardDescription>
                </div>
              </CardHeader>
              <CardContent>
                <div className="rounded-md border">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead className="w-[80px]">Mã LTC</TableHead>
                        <TableHead>Môn học</TableHead>
                        <TableHead className="w-[60px] text-center">Nhóm</TableHead>
                        <TableHead>Giảng viên</TableHead>
                        <TableHead className="text-center">Điểm CC</TableHead>
                        <TableHead className="text-center">Điểm GK</TableHead>
                        <TableHead className="text-center">Điểm CK</TableHead>
                        <TableHead className="text-center">Điểm TK</TableHead>
                        <TableHead className="text-center">Điểm chữ</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {group.registrations.map((reg) => (
                        <TableRow key={reg.MALTC}>
                          <TableCell className="font-medium">{reg.MALTC}</TableCell>
                          <TableCell>{reg.TENMH}</TableCell>
                          <TableCell className="text-center">{reg.NHOM}</TableCell>
                          <TableCell>{reg.HOTENGV}</TableCell>
                          <TableCell className="text-center">{formatGrade(reg.DIEM_CC)}</TableCell>
                          <TableCell className="text-center">{formatGrade(reg.DIEM_GK)}</TableCell>
                          <TableCell className="text-center">{formatGrade(reg.DIEM_CK)}</TableCell>
                          <TableCell className="text-center font-medium">{formatGrade(reg.DIEM_HET_MON)}</TableCell>
                          <TableCell className="text-center">
                            <Badge variant={getGradeColor(reg.DIEM_HET_MON)}>
                              {getLetterGrade(reg.DIEM_HET_MON)}
                            </Badge>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
                
                <div className="mt-4 text-sm text-muted-foreground">
                  <p>Thang điểm: A+ (9.0-10), A (8.5-8.9), B+ (8.0-8.4), B (7.0-7.9), C+ (6.5-6.9), C (5.5-6.4), D+ (5.0-5.4), D (4.0-4.9), F (&lt;4.0)</p>
                  <p>Điểm tổng kết = 10% Điểm CC + 30% Điểm GK + 60% Điểm CK</p>
                </div>
              </CardContent>
            </Card>
          ))}
        </>
      )}
    </div>
  );
} 