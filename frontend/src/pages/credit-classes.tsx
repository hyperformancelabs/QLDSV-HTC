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
import { Input } from '@/components/ui/input';
import { 
  Select, 
  SelectContent, 
  SelectItem, 
  SelectTrigger, 
  SelectValue 
} from '@/components/ui/select';
import { 
  Dialog, 
  DialogContent, 
  DialogDescription, 
  DialogFooter, 
  DialogHeader, 
  DialogTitle 
} from '@/components/ui/dialog';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { LopTinChi, LopTinChiFilter, LopTinChiUpsert, Faculty, Subject, UserRole } from '@/types';
import * as loptinchiService from '@/services/loptinchiService';
import * as facultyService from '@/services/facultyService';
import * as subjectService from '@/services/subjectService';
import { useAuthStore } from '@/store/use-auth-store';
import { ComboboxInput, ComboboxOption } from '@/components/ui/combobox-input';
import { searchLecturers } from '@/services/lecturerAccountService';
import { useCreditClassesAdminStore } from '@/store/use-credit-classes-admin-store';
import { RotateCcw, Save, Plus } from 'lucide-react';
import { cn } from '@/lib/utils';

export default function CreditClassesPage() {
  const { toast } = useToast();
  const { user } = useAuthStore();
  const isPGV = user?.role === UserRole.PGV;

  /* ----------------- Thời điểm hiện tại ----------------- */
  const now = new Date();

  // Xác định học kỳ hiện tại theo quy tắc: HK1 (10-12,1), HK2 (2-5), HK3 (6-9)
  const getCurrentSemester = () => {
    const m = now.getMonth() + 1; // JS month 0-11
    if (m === 1 || m >= 10) return 1;
    if (m >= 2 && m <= 5) return 2;
    return 3; // 6-9
  };

  const currentSemester = getCurrentSemester();

  // Tính niên khóa hiện tại dưới dạng 'YYYY-YYYY+1'.
  const getCurrentAcademicYear = () => {
    const year = now.getFullYear();
    // HK1 bắt đầu từ tháng 8 ⇒ nếu trước tháng 8 (tức HK2,3), niên khóa bắt đầu từ (year-1)
    const startYear = now.getMonth() + 1 >= 8 || currentSemester === 1 ? year : year - 1;
    return `${startYear}-${startYear + 1}`;
  };

  const currentAcademicYear = getCurrentAcademicYear();

  /* ----------------- Helper: xác định lớp quá khứ ----------------- */
  const isSemesterPast = (nienkhoa: string, hocky: number): boolean => {
    const classStartYear = parseInt(nienkhoa.slice(0, 4), 10);
    if (isNaN(classStartYear)) return true; // định dạng lỗi -> xem như quá khứ

    const currentStartYear = parseInt(currentAcademicYear.slice(0, 4), 10);

    // So sánh theo academic year trước – sau
    if (classStartYear < currentStartYear) return true;
    if (classStartYear > currentStartYear) return false; // tương lai

    // Cùng niên khóa – so sánh học kỳ
    return hocky < currentSemester;
  };

  /* ----------------- Danh sách niên khóa & học kỳ ----------------- */
  // Cho bộ lọc: hiển thị 5 năm quá khứ + hiện tại + 4 năm tới
  const currentStartYear = parseInt(currentAcademicYear.slice(0, 4));
  const filterAcademicYears = Array.from({ length: 10 }, (_, i) => {
    const start = currentStartYear - 5 + i; // từ (cur-5) tới (cur+4)
    return `${start}-${start + 1}`;
  }).reverse(); // hiển thị mới nhất trước

  // Cho form tạo/sửa: giữ logic cũ (hiện tại về sau 5 năm)
  const academicYears = Array.from({ length: 5 }, (_, i) => {
    const start = currentStartYear + i;
    return `${start}-${start + 1}`;
  });

  // Hàm trả về các học kỳ hợp lệ cho 1 niên khóa cho trước
  const getValidSemesters = (year: string) => {
    if (year === currentAcademicYear) {
      return [1, 2, 3].filter((hk) => hk >= currentSemester);
    }
    return [1, 2, 3];
  };

  // State for LopTinChi list and filters
  const [loptinchiList, setLopTinChiList] = useState<LopTinChi[]>([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState<LopTinChiFilter>({
    nienkhoa: currentAcademicYear,
    hocky: currentSemester,
    only_available: false,
  });

  // State for form dialog
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [formMode, setFormMode] = useState<'create' | 'update'>('create');
  const [formData, setFormData] = useState<LopTinChiUpsert>({
    NIENKHOA: currentAcademicYear,
    HOCKY: currentSemester,
    MAMH: '',
    NHOM: 1,
    MAGV: '',
    MAKHOA: '',
    SOSVTOITHIEU: 10,
  });
  const [selectedMaltc, setSelectedMaltc] = useState<number | null>(null);

  // Reference data for dropdowns
  const [faculties, setFaculties] = useState<Faculty[]>([]);
  const [subjects, setSubjects] = useState<Subject[]>([]);

  // Giảng viên autocomplete states
  const [lecturerSearchTerm, setLecturerSearchTerm] = useState('');
  const [lecturerOptions, setLecturerOptions] = useState<ComboboxOption[]>([]);
  const [lecturerLoading, setLecturerLoading] = useState(false);

  // Store integration
  const {
    creditClasses,
    actionsStack,
    setCreditClasses,
    addClass,
    editClass,
    toggleCancelClass,
    undo,
    resetChanges,
    saveChanges,
    hasChanges,
  } = useCreditClassesAdminStore();

  // Sync store data to local list for UI reuse
  useEffect(() => {
    setLopTinChiList(creditClasses as LopTinChi[]);
  }, [creditClasses]);

  const [confirmAction, setConfirmAction] = useState<'save' | 'reset' | null>(null);

  // Load initial data
  useEffect(() => {
    fetchLopTinChiList();
    fetchReferenceData();
  }, []);

  // Reload when filters change
  useEffect(() => {
    fetchLopTinChiList();
  }, [filters]);

  // Fetch LopTinChi list with current filters
  const applyClientFilters = (data: LopTinChi[], f: LopTinChiFilter): LopTinChi[] => {
    return data.filter((item) => {
      if (f.nienkhoa && item.NIENKHOA !== f.nienkhoa) return false;
      if (f.hocky !== undefined && item.HOCKY !== f.hocky) return false;
      if (f.makhoa) {
        const itemKhoa = (item.MAKHOA || '').trim().toUpperCase();
        const filterKhoa = f.makhoa.trim().toUpperCase();
        if (itemKhoa !== filterKhoa) return false;
      }
      if (f.only_available && item.HUYLOP) return false;
      return true;
    });
  };

  const fetchLopTinChiList = async () => {
    setLoading(true);
    try {
      const data = await loptinchiService.getLopTinChiList(filters);
      const finalData = applyClientFilters(data, filters);
      // Update store – this resets action stack
      setCreditClasses(finalData);
    } catch (error) {
      toast({
        title: 'Lỗi',
        description: error instanceof Error ? error.message : 'Không thể lấy danh sách lớp tín chỉ',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  // Fetch reference data for dropdowns
  const fetchReferenceData = async () => {
    try {
      // Fetch faculties
      const facultiesData = await facultyService.getAllFaculties();
      setFaculties(facultiesData);

      // Fetch subjects
      const subjectsData = await subjectService.getAllSubjects();
      setSubjects(subjectsData);
    } catch (error) {
      toast({
        title: "Lỗi",
        description: "Không thể lấy dữ liệu tham chiếu",
        variant: "destructive",
      });
    }
  };

  // Handle filter changes
  const handleFilterChange = (key: keyof LopTinChiFilter, value: any) => {
    const normalized = (value === 'all' || value === '') ? undefined : value;
    setFilters(prev => {
      const updated: LopTinChiFilter = { ...prev, [key]: normalized };
      // Không áp ràng buộc quá khứ trên bộ lọc – luôn chấp nhận 1-3
      return updated;
    });
  };

  // Open dialog for creating a new LopTinChi
  const handleOpenCreateDialog = () => {
    setFormMode('create');
    setLecturerSearchTerm('');
    setLecturerOptions([]);
    setFormData({
      NIENKHOA: currentAcademicYear,
      HOCKY: currentSemester,
      MAMH: '',
      NHOM: 1,
      MAGV: '',
      MAKHOA: user?.makhoa || '',
      SOSVTOITHIEU: 10
    });
    setIsDialogOpen(true);
  };

  // Open dialog for updating an existing LopTinChi
  const handleOpenUpdateDialog = (loptinchi: LopTinChi) => {
    setFormMode('update');
    if (subjects.length === 0 || faculties.length === 0) {
      fetchReferenceData();
    }
    setSelectedMaltc(loptinchi.MALTC);
    setLecturerSearchTerm(loptinchi.HOTENGV || '');
    fetchLecturerOptions(loptinchi.HOTENGV || '');
    setFormData({
      MALTC: loptinchi.MALTC,
      NIENKHOA: loptinchi.NIENKHOA,
      HOCKY: loptinchi.HOCKY,
      MAMH: loptinchi.MAMH.trim(),
      NHOM: loptinchi.NHOM,
      MAGV: loptinchi.MAGV,
      MAKHOA: loptinchi.MAKHOA.trim(),
      SOSVTOITHIEU: loptinchi.SOSVTOITHIEU
    });
    setIsDialogOpen(true);
  };

  // Handle form input changes
  const handleInputChange = (key: keyof LopTinChiUpsert, value: any) => {
    setFormData(prev => ({
      ...prev,
      [key]: value
    }));
  };

  // Submit form to create or update LopTinChi
  const handleSubmitForm = async () => {
    try {
      if (formMode === 'create') {
        // Build display data from references
        const subjectObj = subjects.find(s => s.mamh === formData.MAMH.trim());
        const facultyObj = faculties.find(f => f.makhoa === formData.MAKHOA.trim());
        const lecturerObj = lecturerOptions.find(o => o.value === formData.MAGV);

        const newClass: LopTinChi = {
          MALTC: -Date.now(),
          NIENKHOA: formData.NIENKHOA,
          HOCKY: formData.HOCKY,
          MAMH: formData.MAMH.trim(),
          TENMH: subjectObj?.tenmh || '',
          NHOM: formData.NHOM,
          MAGV: formData.MAGV,
          HOTENGV: lecturerObj?.label || '',
          MAKHOA: formData.MAKHOA.trim(),
          TENKHOA: facultyObj?.tenkhoa || '',
          SOSVTOITHIEU: formData.SOSVTOITHIEU,
          SOSVDANGKY: 0,
          HUYLOP: false,
        };

        addClass(newClass);
        toast({ title: 'Đã thêm', description: 'Lớp tín chỉ mới được thêm vào danh sách tạm.' });
      } else {
        const subjectObj = subjects.find(s => s.mamh === formData.MAMH.trim());
        const facultyObj = faculties.find(f => f.makhoa === formData.MAKHOA.trim());
        const lecturerObj = lecturerOptions.find(o => o.value === formData.MAGV);

        const updatedClass: LopTinChi = {
          MALTC: formData.MALTC as number,
          NIENKHOA: formData.NIENKHOA,
          HOCKY: formData.HOCKY,
          MAMH: formData.MAMH.trim(),
          TENMH: subjectObj?.tenmh || '',
          NHOM: formData.NHOM,
          MAGV: formData.MAGV,
          HOTENGV: lecturerObj?.label || '',
          MAKHOA: formData.MAKHOA.trim(),
          TENKHOA: facultyObj?.tenkhoa || '',
          SOSVTOITHIEU: formData.SOSVTOITHIEU,
          SOSVDANGKY: 0,
          HUYLOP: false,
        };
        editClass(updatedClass);
        toast({ title: 'Đã cập nhật', description: 'Thông tin lớp tín chỉ đã được cập nhật tạm.' });
      }
      setIsDialogOpen(false);
    } catch (error) {
      toast({ title: 'Lỗi', description: 'Không thể cập nhật dữ liệu tạm', variant: 'destructive' });
    }
  };

  // Replace cancel/restore handlers
  const handleToggleCancel = (maltc: number) => {
    toggleCancelClass(maltc);
  };

  // Save, reset, undo handlers
  const handleConfirmSave = async () => {
    setConfirmAction(null);
    setLoading(true);
    const { toCreate, toUpdate, toCancel, toRestore } = saveChanges();
    try {
      // Process cancel first
      for (const id of toCancel) {
        await loptinchiService.cancelLopTinChi(id);
      }
      // Process restore
      for (const id of toRestore) {
        await loptinchiService.restoreLopTinChi(id);
      }
      // Process create
      for (const c of toCreate) {
        await loptinchiService.createLopTinChi(c);
      }
      // Process update
      for (const up of toUpdate) {
        await loptinchiService.updateLopTinChi(up.maltc, up.data);
      }
      await fetchLopTinChiList();
      toast({ title: 'Thành công', description: 'Tất cả thay đổi đã được ghi.' });
    } catch (error) {
      toast({ title: 'Lỗi', description: 'Không thể ghi thay đổi', variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  };

  const handleConfirmReset = () => {
    setConfirmAction(null);
    resetChanges();
    toast({ title: 'Đã huỷ', description: 'Mọi thay đổi tạm đã bị huỷ.' });
  };

  const handleUndo = () => {
    undo();
  };

  // Search lecturers by name or id
  const fetchLecturerOptions = async (keyword: string) => {
    setLecturerLoading(true);
    try {
      const lecturers = await searchLecturers(keyword);
      const opts: ComboboxOption[] = lecturers.map((lec) => ({
        label: `${lec.HO} ${lec.TEN}`.trim() + (lec.HasLogin ? '' : ''),
        value: lec.MAGV,
        description: `Khoa: ${lec.TENKHOA}`,
      }));
      setLecturerOptions(opts);
    } catch (error) {
      console.error('Search lecturer error:', error);
    } finally {
      setLecturerLoading(false);
    }
  };

  return (
    <div className="container mx-auto py-6">
      <h1 className="text-3xl font-bold mb-6">Quản lý Lớp Tín Chỉ</h1>
      
      {/* Filters */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Bộ lọc</CardTitle>
          <CardDescription>Lọc danh sách lớp tín chỉ theo các tiêu chí</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div>
              <label className="text-sm font-medium mb-1 block">Niên khóa</label>
              <Select
                value={filters.nienkhoa || undefined}
                onValueChange={(value) => handleFilterChange('nienkhoa', value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Chọn niên khóa" />
                </SelectTrigger>
                <SelectContent>
                  {filterAcademicYears.map(year => (
                    <SelectItem key={year} value={year}>{year}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div>
              <label className="text-sm font-medium mb-1 block">Học kỳ</label>
              <Select
                value={filters.hocky?.toString() || undefined}
                onValueChange={(value) => handleFilterChange('hocky', value ? parseInt(value) : undefined)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Chọn học kỳ" />
                </SelectTrigger>
                <SelectContent>
                  {[1,2,3].map((hk) => (
                    <SelectItem key={hk} value={hk.toString()}>{`Học kỳ ${hk}`}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div>
              <label className="text-sm font-medium mb-1 block">Khoa</label>
              <Select
                value={filters.makhoa || undefined}
                onValueChange={(value) => handleFilterChange('makhoa', value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Chọn khoa" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Tất cả</SelectItem>
                  {faculties.map(faculty => (
                    <SelectItem key={faculty.makhoa} value={faculty.makhoa}>
                      {faculty.tenkhoa}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div className="flex flex-col justify-end">
              <div className="flex items-center space-x-2 mb-2">
                <input
                  type="checkbox"
                  id="only_available"
                  checked={filters.only_available}
                  onChange={(e) => handleFilterChange('only_available', e.target.checked)}
                  className="h-4 w-4 rounded border-gray-300"
                />
                <label htmlFor="only_available" className="text-sm font-medium">
                  Chỉ hiển thị lớp chưa hủy
                </label>
              </div>
              <Button 
                variant="outline" 
                onClick={() => {
                  setFilters({
                    nienkhoa: currentAcademicYear,
                    hocky: currentSemester,
                    only_available: filters.only_available,
                    makhoa: filters.makhoa
                  });
                }}
              >
                Kỳ hiện tại
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
      
      {/* Action buttons */}
      <div className="flex justify-between mb-4">
        <div>
          <Button 
            onClick={fetchLopTinChiList}
            variant="outline"
          >
            Làm mới
          </Button>
          {hasChanges() && (
            <Button variant="outline" size="sm" className="ml-2" onClick={handleUndo} disabled={actionsStack.length===0}><RotateCcw className="h-4 w-4 mr-1"/>Hoàn tác</Button>) }
          {hasChanges() && (
            <Button variant="outline" size="sm" className="ml-2" onClick={() => setConfirmAction('reset')}>Huỷ thay đổi</Button>) }
          {hasChanges() && (
            <Button variant="default" size="sm" className="ml-2" onClick={() => setConfirmAction('save')}><Save className="h-4 w-4 mr-1"/>Lưu thay đổi</Button>) }
        </div>
        
        {isPGV && (
          <Button onClick={handleOpenCreateDialog}>
            Tạo lớp tín chỉ mới
          </Button>
        )}
      </div>
      
      {/* LopTinChi Table */}
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
              <TableHead className="text-center">Trạng thái</TableHead>
              {isPGV && <TableHead className="text-right">Thao tác</TableHead>}
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={isPGV ? 11 : 10} className="text-center">
                  Đang tải dữ liệu...
                </TableCell>
              </TableRow>
            ) : loptinchiList.length === 0 ? (
              <TableRow>
                <TableCell colSpan={isPGV ? 11 : 10} className="text-center">
                  Không có dữ liệu lớp tín chỉ
                </TableCell>
              </TableRow>
            ) : (
              loptinchiList.map((ltc) => (
                <TableRow key={ltc.MALTC} className={cn(
                  (ltc as any).isNew && 'bg-green-50',
                  (ltc as any).isModified && 'bg-yellow-50',
                  (ltc as any).isDeleted && 'bg-red-50'
                )}>
                  <TableCell className="font-medium">{(ltc as any).isNew ? 'Mới' : ltc.MALTC}</TableCell>
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
                  <TableCell className="text-center">
                    {ltc.HUYLOP ? (
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                        Đã hủy
                      </span>
                    ) : (
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        Đang mở
                      </span>
                    )}
                  </TableCell>
                  {isPGV && (
                    <TableCell className="text-right">
                      {isSemesterPast(ltc.NIENKHOA, ltc.HOCKY) ? (
                        <span className="text-xs text-muted-foreground">Quá hạn</span>
                      ) : (
                        <div className="flex justify-end space-x-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleOpenUpdateDialog(ltc)}
                          >
                            Sửa
                          </Button>

                          {ltc.HUYLOP ? (
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleToggleCancel(ltc.MALTC)}
                            >
                              Khôi phục
                            </Button>
                          ) : (
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleToggleCancel(ltc.MALTC)}
                              className="text-red-500 hover:text-red-700"
                            >
                              Hủy
                            </Button>
                          )}
                        </div>
                      )}
                    </TableCell>
                  )}
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>
      
      {/* Create/Update Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="sm:max-w-[550px]">
          <DialogHeader>
            <DialogTitle>
              {formMode === 'create' ? 'Tạo lớp tín chỉ mới' : 'Cập nhật lớp tín chỉ'}
            </DialogTitle>
            <DialogDescription>
              Nhập thông tin chi tiết cho lớp tín chỉ.
            </DialogDescription>
          </DialogHeader>
          
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Niên khóa</label>
                <Select
                  value={formData.NIENKHOA || undefined}
                  onValueChange={(value) => handleInputChange('NIENKHOA', value)}
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
              
              <div className="space-y-2">
                <label className="text-sm font-medium">Học kỳ</label>
                <Select
                  value={formData.HOCKY.toString()}
                  onValueChange={(value) => handleInputChange('HOCKY', parseInt(value))}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Chọn học kỳ" />
                  </SelectTrigger>
                  <SelectContent>
                    {getValidSemesters(formData.NIENKHOA).map((hk) => (
                      <SelectItem key={hk} value={hk.toString()}>
                        {`Học kỳ ${hk}`}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            
            <div className="space-y-2">
              <label className="text-sm font-medium">Môn học</label>
              <Select
                value={formData.MAMH || undefined}
                onValueChange={(value) => handleInputChange('MAMH', value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Chọn môn học" />
                </SelectTrigger>
                <SelectContent>
                  {subjects.map(subject => (
                    <SelectItem key={subject.mamh} value={subject.mamh}>
                      {subject.tenmh}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Nhóm</label>
                <Input
                  type="number"
                  min="1"
                  value={formData.NHOM}
                  onChange={(e) => handleInputChange('NHOM', parseInt(e.target.value))}
                />
              </div>
              
              <div className="space-y-2">
                <label className="text-sm font-medium">Số SV tối thiểu</label>
                <Input
                  type="number"
                  min="1"
                  value={formData.SOSVTOITHIEU}
                  onChange={(e) => handleInputChange('SOSVTOITHIEU', parseInt(e.target.value))}
                />
              </div>
            </div>
            
            <div className="space-y-2">
              <label className="text-sm font-medium">Giảng viên</label>
              <ComboboxInput
                options={lecturerOptions}
                value={formData.MAGV}
                inputValue={lecturerSearchTerm}
                loading={lecturerLoading}
                placeholder="Nhập tên hoặc mã giảng viên..."
                onValueChange={(val) => {
                  handleInputChange('MAGV', val);
                }}
                onInputChange={(val) => {
                  setLecturerSearchTerm(val);
                  fetchLecturerOptions(val);
                }}
              />
            </div>
            
            <div className="space-y-2">
              <label className="text-sm font-medium">Khoa</label>
              <Select
                value={formData.MAKHOA || undefined}
                onValueChange={(value) => handleInputChange('MAKHOA', value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Chọn khoa" />
                </SelectTrigger>
                <SelectContent>
                  {faculties.map(faculty => (
                    <SelectItem key={faculty.makhoa} value={faculty.makhoa}>
                      {faculty.tenkhoa}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
              Hủy
            </Button>
            <Button onClick={handleSubmitForm}>
              {formMode === 'create' ? 'Tạo lớp' : 'Cập nhật'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Confirmation dialogs */}
      <Dialog open={confirmAction === 'save'} onOpenChange={() => setConfirmAction(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Xác nhận lưu thay đổi</DialogTitle>
            <DialogDescription>Bạn có chắc chắn muốn lưu tất cả thay đổi? Thao tác này không thể hoàn tác.</DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmAction(null)}>Hủy</Button>
            <Button onClick={handleConfirmSave} disabled={loading}>Xác nhận</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={confirmAction === 'reset'} onOpenChange={() => setConfirmAction(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Huỷ tất cả thay đổi</DialogTitle>
            <DialogDescription>Bạn có chắc chắn muốn huỷ toàn bộ thay đổi đang thực hiện?</DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmAction(null)}>Giữ thay đổi</Button>
            <Button variant="destructive" onClick={handleConfirmReset}>Huỷ thay đổi</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
} 