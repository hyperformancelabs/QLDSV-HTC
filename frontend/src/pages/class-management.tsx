/**
 * Class and Student Management Page
 * Split view with class list on left and student list on right
 * Allows creating, editing, and deleting classes and students
 * Access: PGV (full access), KHOA (view only)
 */
import { useEffect, useState } from 'react';
import { Navigate } from 'react-router-dom';
import { useToast } from '@/components/ui/use-toast';
import { UserRole } from '@/types';
import { useAuthStore } from '@/store/use-auth-store';
import { useClassesStore } from '@/store/use-classes-store';
import { useStudentsStore } from '@/store/use-students-store';

import { 
  fetchClasses, 
  upsertClass, 
  deleteClass, 
  bulkUpsertClasses, 
  validateClass, 
  checkClassCodeExists, 
  checkClassNameExists,
  Class
} from '@/services/classService';

import {
  fetchStudentsByClass,
  createStudent,
  updateStudent,
  deleteStudent,
  validateStudent,
  checkStudentExists,
  Student
} from '@/services/studentService';

import {
  fetchFaculties,
  Faculty
} from '@/services/facultyService';

// Import UI components
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle
} from '@/components/ui/dialog';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';

// Import icons
import {
  Plus,
  Save,
  RotateCcw,
  XCircle,
  Search,
  ArrowUpDown,
  ChevronLeft,
  ChevronRight,
  SkipBack,
  SkipForward,
  Pencil,
  Trash2,
  X,
  Check,
  Users,
  Maximize2,
  Minimize2,
} from 'lucide-react';
import { cn } from '@/lib/utils';

/**
 * Main class management page component with subform for student management
 */
export default function ClassManagementPage() {
  const { user } = useAuthStore();
  const { toast } = useToast();
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [leftRatio, setLeftRatio] = useState(50); // percentage 0-100

  // Permission checks
  const role = user?.role;
  const canView = role === UserRole.PGV || role === UserRole.KHOA;
  const canEdit = role === UserRole.PGV;

  // Redirect if no permission
  if (!user || !canView) {
    return <Navigate to="/dashboard" replace />;
  }

  const startDragging = (e: React.MouseEvent<HTMLDivElement>) => {
    e.preventDefault();
    const startX = e.clientX;
    const startRatio = leftRatio;

    const onMouseMove = (moveEvt: MouseEvent) => {
      const delta = moveEvt.clientX - startX;
      const newRatio = Math.min(80, Math.max(20, startRatio + (delta / window.innerWidth) * 100));
      setLeftRatio(newRatio);
    };

    const onMouseUp = () => {
      window.removeEventListener('mousemove', onMouseMove);
      window.removeEventListener('mouseup', onMouseUp);
    };

    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('mouseup', onMouseUp);
  };

  return (
    <div
      className={cn(
        isFullscreen
          ? "fixed inset-0 z-50 w-screen h-screen bg-white p-4 overflow-auto"
          : "container py-6"
      )}
    >
      {/* Header / Fullscreen toggle */}
      {isFullscreen ? (
        <div className="flex justify-end mb-2">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => setIsFullscreen(false)}
            title="Thoát toàn màn hình"
          >
            <Minimize2 className="h-5 w-5" />
          </Button>
        </div>
      ) : (
        <div className="flex justify-between items-center mb-4">
          <h1 className="text-2xl font-bold">Quản lý lớp & sinh viên</h1>
          <Button
            variant="ghost"
            size="icon"
            onClick={() => setIsFullscreen(true)}
            title="Toàn màn hình"
          >
            <Maximize2 className="h-5 w-5" />
          </Button>
        </div>
      )}

      {/* Split view layout */}
      {isFullscreen ? (
        <div className="flex gap-2" style={{height: 'calc(100vh - 6rem)'}}>
          <div
            className="border rounded-lg p-4 h-full overflow-hidden"
            style={{flex: `0 0 ${leftRatio}%`}}
          >
            <ClassesPanel canEdit={canEdit} isFullscreen={isFullscreen} />
          </div>
          {/* Draggable divider */}
          <div
            className="w-1 bg-muted cursor-col-resize"
            onMouseDown={startDragging}
          />
          <div
            className="border rounded-lg p-4 h-full overflow-hidden flex-1"
          >
            <StudentsPanel canEdit={canEdit} isFullscreen={isFullscreen} />
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-5 gap-4">
          <div className="lg:col-span-2 border rounded-lg p-4 h-[calc(100vh-14rem)] lg:h-[calc(100vh-8rem)]">
            <ClassesPanel canEdit={canEdit} isFullscreen={isFullscreen} />
          </div>
          <div className="lg:col-span-3 border rounded-lg p-4 h-[calc(100vh-14rem)] lg:h-[calc(100vh-8rem)]">
            <StudentsPanel canEdit={canEdit} isFullscreen={isFullscreen} />
          </div>
        </div>
      )}
    </div>
  );
}

/**
 * ClassesPanel component renders the left side of the split view
 */
function ClassesPanel({ canEdit, isFullscreen }: { canEdit: boolean; isFullscreen: boolean }) {
  const { toast } = useToast();
  const [isLoading, setIsLoading] = useState(false);
  const [confirmAction, setConfirmAction] = useState<'save' | 'exit' | 'reset' | null>(null);
  const [codeExists, setCodeExists] = useState(false);
  const [nameExists, setNameExists] = useState(false);
  const [faculties, setFaculties] = useState<Faculty[]>([]);
  
  // Filters
  const [facultyFilter, setFacultyFilter] = useState<string | null>("all");
  const [yearFilter, setYearFilter] = useState<string | null>("all");
  const [availableYears, setAvailableYears] = useState<string[]>([]);

  // Classes store
  const {
    classes,
    setClasses,
    addClass,
    editClass,
    deleteClass: storeDeleteClass,
    selectClass,
    selectedClass,
    undo,
    resetChanges,
    saveChanges,
    hasChanges,
    setSearchTerm,
    setSortField,
    toggleSortDirection,
    setPageSize,
    setCurrentPage,
    filteredClasses,
    paginatedClasses,
    totalPages,
    currentPage,
    pageSize,
    sortField,
    sortDirection,
    searchTerm
  } = useClassesStore();

  // Editing state
  const [editingId, setEditingId] = useState<string | null>(null);
  const [inlineEditData, setInlineEditData] = useState<Class | null>(null);
  const [validationErrors, setValidationErrors] = useState<{[key: string]: string}>({});

  // Load classes and faculties on component mount
  useEffect(() => {
    loadClasses();
    loadFaculties();
  }, []);

  // Extract unique years from classes for the year filter
  useEffect(() => {
    if (classes.length > 0) {
      const years = new Set<string>();
      classes.forEach(cls => {
        if (cls.KHOAHOC) {
          const startYear = cls.KHOAHOC.split('-')[0];
          if (startYear) {
            years.add(startYear);
          }
        }
      });
      setAvailableYears(Array.from(years).sort());
    }
  }, [classes]);

  // Check for duplicate code and name when adding/editing
  useEffect(() => {
    if (inlineEditData && (editingId === 'new' || inlineEditData.MALOP !== editingId)) {
      const checkCode = async () => {
        if (inlineEditData.MALOP.trim()) {
          const exists = await checkClassCodeExists(inlineEditData.MALOP);
          setCodeExists(exists);
          if (exists) {
            setValidationErrors(prev => ({
              ...prev,
              MALOP: 'Mã lớp đã tồn tại'
            }));
          } else {
            setValidationErrors(prev => {
              const { MALOP, ...rest } = prev;
              return rest;
            });
          }
        }
      };
      
      const checkName = async () => {
        if (inlineEditData.TENLOP.trim()) {
          const exists = await checkClassNameExists(inlineEditData.TENLOP);
          setNameExists(exists);
          if (exists) {
            setValidationErrors(prev => ({
              ...prev,
              TENLOP: 'Tên lớp đã tồn tại'
            }));
          } else {
            setValidationErrors(prev => {
              const { TENLOP, ...rest } = prev;
              return rest;
            });
          }
        }
      };
      
      // Run validation checks
      if (editingId === 'new') {
        checkCode();
        checkName();
      }
    }
  }, [inlineEditData?.MALOP, inlineEditData?.TENLOP, editingId]);

  // Load classes from API with filters
  const loadClasses = async () => {
    try {
      setIsLoading(true);
      const filters = {
        makhoa: facultyFilter === "all" ? undefined : facultyFilter,
        khoahoc: yearFilter === "all" ? undefined : yearFilter ? `${yearFilter}-${Number(yearFilter) + 4}` : undefined
      };
      const data = await fetchClasses(filters);
      setClasses(data);
      setIsLoading(false);
    } catch (error: any) {
      toast({
        title: "Lỗi",
        description: error.message,
        variant: "destructive"
      });
      setIsLoading(false);
    }
  };
  
  // Apply filters when they change
  useEffect(() => {
    loadClasses();
  }, [facultyFilter, yearFilter]);

  // Load faculties from API
  const loadFaculties = async () => {
    try {
      const data = await fetchFaculties();
      setFaculties(data);
    } catch (error: any) {
      toast({ 
        title: "Lỗi",
        description: "Không thể tải danh sách khoa",
        variant: "destructive"
      });
    }
  };

  // Class management handlers
  const handleAddClass = () => {
    if (!canEdit || editingId) return;
    
    const newClass: Class = {
      MALOP: '',
      TENLOP: '',
      KHOAHOC: '',
      MAKHOA: '',
      SOLUONGSV: 0
    };
    
    setEditingId('new');
    setInlineEditData(newClass);
    setValidationErrors({});
  };

  const handleEditClass = (cls: Class) => {
    if (!canEdit || editingId) return;
    
    setEditingId(cls.MALOP);
    setInlineEditData({...cls});
    setValidationErrors({});
  };

  const handleCancelEdit = () => {
    // If there are changes, show confirmation dialog
    if (
      inlineEditData && 
      (inlineEditData.MALOP.trim() || inlineEditData.TENLOP.trim()) && 
      editingId === 'new'
    ) {
      setConfirmAction('exit');
      return;
    }
    
    // Otherwise just cancel
    setEditingId(null);
    setInlineEditData(null);
    setValidationErrors({});
    setCodeExists(false);
    setNameExists(false);
  };

  const handleSaveEdit = () => {
    if (!inlineEditData) return;
    
    // Validate all fields
    const error = validateClass(inlineEditData, editingId === 'new');
    if (error) {
      toast({
        title: "Lỗi dữ liệu",
        description: error,
        variant: "destructive"
      });
      return;
    }
    
    // Check for validation errors from duplicate checks
    if (Object.keys(validationErrors).length > 0) {
      const errorMessage = Object.values(validationErrors).join(', ');
      toast({
        title: "Lỗi dữ liệu",
        description: errorMessage,
        variant: "destructive"
      });
      return;
    }
    
    // Keep track of the saved class to highlight it later
    const savedClass = {...inlineEditData};
    const isNew = editingId === 'new';
    
    if (isNew) {
      addClass(inlineEditData);
      
      // Select the newly added class and navigate to its page
      setTimeout(() => {
        // Find the new class in the filtered list
        const allFilteredClasses = filteredClasses();
        const index = allFilteredClasses.findIndex(c => c.MALOP === savedClass.MALOP);
        
        if (index >= 0) {
          // Calculate which page the class is on
          const targetPage = Math.floor(index / pageSize) + 1;
          setCurrentPage(targetPage);
          selectClass(savedClass.MALOP);
        }
      }, 100);
    } else {
      editClass(inlineEditData);
    }
    
    setEditingId(null);
    setInlineEditData(null);
    setValidationErrors({});
    setCodeExists(false);
    setNameExists(false);
    
    // Show success message
    toast({
      title: isNew ? "Thêm mới thành công" : "Cập nhật thành công",
      description: `${isNew ? 'Đã thêm' : 'Đã cập nhật'} lớp ${savedClass.MALOP}`,
    });
  };

  const handleDeleteClass = async (malop: string) => {
    if (!canEdit) return;
    
    try {
      const cls = classes.find(c => c.MALOP === malop);
      if (cls && cls.SOSINHVIEN && cls.SOSINHVIEN > 0) {
        toast({
          title: "Không thể xóa",
          description: `Lớp ${malop} có ${cls.SOSINHVIEN} sinh viên, không thể xóa.`,
          variant: "destructive"
        });
        return;
      }
      
      // Mark the class as deleted without showing confirmation
      storeDeleteClass(malop);
      
      // Show toast notification
      toast({
        title: "Đánh dấu xóa",
        description: `Lớp ${malop} đã được đánh dấu để xóa. Bấm 'Ghi' để lưu thay đổi.`,
      });
    } catch (error: any) {
      toast({
        title: "Lỗi",
        description: error.message,
        variant: "destructive"
      });
    }
  };

  const handleSelectClass = (malop: string) => {
    selectClass(malop);
  };

  const handleInlineInputChange = (field: keyof Class, value: string | number) => {
    if (!inlineEditData) return;
    
    setInlineEditData({
      ...inlineEditData,
      [field]: value
    });
    
    // Clear validation for changed field
    setValidationErrors(prev => {
      const { [field]: _, ...rest } = prev;
      return rest;
    });
  };

  const handleSaveChanges = () => {
    // Before saving changes, confirm with user
    setConfirmAction('save');
  };

  const handleResetChanges = () => {
    // Before resetting changes, confirm with user
    if (hasChanges()) {
      setConfirmAction('reset');
    }
  };

  const handleConfirmSave = async () => {
    setConfirmAction(null);
    setIsLoading(true);
    
    try {
      // Process each action in the stack - these should match what's in the students array
      // Added students
      const addedClasses = classes.filter(c => c.isNew && !c.isDeleted);
      // Modified students
      const modifiedClasses = classes.filter(c => c.isModified && !c.isNew && !c.isDeleted);
      // Deleted classes
      const deletedClasses = classes.filter(c => c.isDeleted);
      
      // Process additions/updates
      if (addedClasses.length > 0) {
        await bulkUpsertClasses(addedClasses);
      }
      
      if (modifiedClasses.length > 0) {
        await bulkUpsertClasses(modifiedClasses);
      }
      
      // Process deletions
      for (const cls of deletedClasses) {
        await deleteClass(cls.MALOP);
      }
      
      // Reload classes to get fresh data
      await loadClasses();
      
      toast({
        title: "Thành công",
        description: "Đã lưu tất cả thay đổi"
      });
    } catch (error: any) {
      toast({
        title: "Lỗi",
        description: error.message || "Không thể lưu thay đổi",
        variant: "destructive"
      });
    } finally {
      setIsLoading(false);
    }
  };
  
  const handleConfirmReset = () => {
    setConfirmAction(null);
    resetChanges();
    toast({
      title: "Đã hủy thay đổi", 
      description: "Đã hoàn tác tất cả thay đổi chưa lưu"
    });
  };

  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(e.target.value);
  };

  const handleSortClick = (field: keyof Class) => {
    if (sortField === field) {
      toggleSortDirection();
    } else {
      setSortField(field);
    }
  };

  const handlePageSizeChange = (value: string) => {
    setPageSize(parseInt(value));
  };

  return (
    <div className="flex flex-col h-full">
      {/* Panel header and actions */}
      <>
        <div className="flex justify-between items-center mb-2">
          <h2 className="text-lg font-semibold flex items-center gap-1">
            <Users size={18} />
            Danh sách lớp
          </h2>
          {/* Action buttons */}
          <div className="flex space-x-2">
            {canEdit && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => handleAddClass()}
                disabled={!!editingId || isLoading}
              >
                <Plus className="h-4 w-4 mr-1" />
                Thêm lớp
              </Button>
            )}
            {canEdit && hasChanges() && (
              <>
                <Button variant="default" size="sm" onClick={handleSaveChanges} disabled={!!editingId || isLoading}>
                  <Save className="h-4 w-4 mr-1" />
                  Ghi
                </Button>
                <Button variant="outline" size="sm" onClick={undo} disabled={!!editingId || isLoading} title="Hoàn tác thao tác gần nhất">
                  <RotateCcw className="h-4 w-4 mr-1" />
                  Hoàn tác
                </Button>
                <Button variant="outline" size="sm" onClick={handleResetChanges} disabled={!!editingId || isLoading} title="Hủy tất cả thay đổi">
                  <XCircle className="h-4 w-4 mr-1" />
                  Hủy thay đổi
                </Button>
              </>
            )}
          </div>
        </div>

        {/* Search bar */}
        <div className="relative mb-2">
          <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input placeholder="Tìm kiếm lớp..." className="pl-8" value={searchTerm} onChange={handleSearch} disabled={isLoading} />
        </div>

        {/* Filters */}
        <div className="flex gap-2 mb-2 items-center">
          <div className="w-1/2">
            <Select
              value={facultyFilter || "all"}
              onValueChange={(value) => setFacultyFilter(value === "all" ? null : value)}
            >
              <SelectTrigger className="h-9">
                <SelectValue placeholder="Lọc theo khoa" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Tất cả khoa</SelectItem>
                {faculties.map(faculty => (
                  <SelectItem key={faculty.MAKHOA} value={faculty.MAKHOA}>
                    {faculty.TENKHOA}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="w-1/2">
            <Select 
              value={yearFilter || "all"}
              onValueChange={(value) => setYearFilter(value === "all" ? null : value)}
            >
              <SelectTrigger className="h-9">
                <SelectValue placeholder="Lọc theo khóa" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Tất cả khóa</SelectItem>
                {availableYears.map(year => (
                  <SelectItem key={year} value={year}>
                    {year}-{Number(year) + 4}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>
      </>
      
      {/* Classes list */}
      <div className="flex-1 overflow-y-auto">
        <Table>
          <TableHeader className="sticky top-0 bg-background">
            <TableRow>
              <TableHead className="w-28 cursor-pointer" onClick={() => handleSortClick('MALOP')}>
                <div className="flex items-center">
                  Mã lớp
                  {sortField === 'MALOP' && (
                    <ArrowUpDown className={cn(
                      "ml-1 h-4 w-4",
                      sortDirection === 'desc' ? "transform rotate-180" : ""
                    )} />
                  )}
                </div>
              </TableHead>
              <TableHead className="w-60 cursor-pointer" onClick={() => handleSortClick('TENLOP')}>
                <div className="flex items-center">
                  Tên lớp
                  {sortField === 'TENLOP' && (
                    <ArrowUpDown className={cn(
                      "ml-1 h-4 w-4",
                      sortDirection === 'desc' ? "transform rotate-180" : ""
                    )} />
                  )}
                </div>
              </TableHead>
              <TableHead className="w-44 cursor-pointer" onClick={() => handleSortClick('KHOAHOC')}>
                <div className="flex items-center">
                  Niên khóa
                  {sortField === 'KHOAHOC' && (
                    <ArrowUpDown className={cn(
                      "ml-1 h-4 w-4",
                      sortDirection === 'desc' ? "transform rotate-180" : ""
                    )} />
                  )}
                </div>
              </TableHead>
              <TableHead className="w-72 cursor-pointer" onClick={() => handleSortClick('MAKHOA')}>
                <div className="flex items-center">
                  Khoa
                  {sortField === 'MAKHOA' && (
                    <ArrowUpDown className={cn(
                      "ml-1 h-4 w-4",
                      sortDirection === 'desc' ? "transform rotate-180" : ""
                    )} />
                  )}
                </div>
              </TableHead>
              <TableHead className="w-28 text-center cursor-pointer" onClick={() => handleSortClick('SOSINHVIEN')}>
                <div className="flex items-center justify-center">
                  SV
                  {sortField === 'SOSINHVIEN' && (
                    <ArrowUpDown className={cn(
                      "ml-1 h-4 w-4",
                      sortDirection === 'desc' ? "transform rotate-180" : ""
                    )} />
                  )}
                </div>
              </TableHead>
              <TableHead className="w-1/5 text-right">
                {canEdit ? 'Thao tác' : ''}
              </TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-10">
                  Đang tải...
                </TableCell>
              </TableRow>
            ) : paginatedClasses().length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-10">
                  Không có lớp nào
                </TableCell>
              </TableRow>
            ) : (
              paginatedClasses().map(cls => (
                <TableRow 
                  key={cls.MALOP} 
                  className={cn(
                    selectedClass?.MALOP === cls.MALOP ? "bg-muted" : "",
                    cls.isNew ? "bg-green-50" : "",
                    cls.isModified ? "bg-yellow-50" : "",
                    cls.isDeleted ? "bg-red-50" : "",
                    "cursor-pointer"
                  )}
                  onClick={() => handleSelectClass(cls.MALOP)}
                >
                  {editingId === cls.MALOP ? (
                    <>
                      <TableCell>
                        <Input
                          value={inlineEditData?.MALOP || ''}
                          onChange={(e) => handleInlineInputChange('MALOP', e.target.value)}
                          className={validationErrors.MALOP ? "border-red-500" : ""}
                          disabled={editingId !== 'new'}
                        />
                        {validationErrors.MALOP && (
                          <p className="text-xs text-red-500 mt-1">{validationErrors.MALOP}</p>
                        )}
                      </TableCell>
                      <TableCell>
                        <Input
                          value={inlineEditData?.TENLOP || ''}
                          onChange={(e) => handleInlineInputChange('TENLOP', e.target.value)}
                          className={validationErrors.TENLOP ? "border-red-500" : ""}
                        />
                        {validationErrors.TENLOP && (
                          <p className="text-xs text-red-500 mt-1">{validationErrors.TENLOP}</p>
                        )}
                      </TableCell>
                      <TableCell>
                        {/* Year range selection for KHOAHOC */}
                        <div className="flex flex-col space-y-1">
                          {/* Start year */}
                          <Select
                            value={inlineEditData?.KHOAHOC.split('-')[0] || ''}
                            onValueChange={(value) => {
                              const endYear = inlineEditData?.KHOAHOC.split('-')[1] || String(Number(value) + 4);
                              handleInlineInputChange('KHOAHOC', `${value}-${endYear}`);
                            }}
                            disabled={editingId !== 'new' && Number(inlineEditData?.KHOAHOC.split('-')[0]) < new Date().getFullYear()}
                          >
                            <SelectTrigger className={cn('w-24', validationErrors.KHOAHOC && 'border-red-500')}>
                              <SelectValue placeholder="Năm bắt đầu" />
                            </SelectTrigger>
                            <SelectContent>
                              {(() => {
                                const current = new Date().getFullYear();
                                return Array.from({ length: 4 }).map((_, idx) => {
                                  const year = current + idx;
                                  return <SelectItem key={year} value={String(year)}>{year}</SelectItem>;
                                });
                              })()}
                            </SelectContent>
                          </Select>
                          <span className="self-center">-</span>
                          {/* End year */}
                          <Select
                            value={inlineEditData?.KHOAHOC.split('-')[1] || ''}
                            onValueChange={(value) => {
                              const startYear = inlineEditData?.KHOAHOC.split('-')[0] || String(Number(value) - 4);
                              handleInlineInputChange('KHOAHOC', `${startYear}-${value}`);
                            }}
                          >
                            <SelectTrigger className={cn('w-24', validationErrors.KHOAHOC && 'border-red-500')}>
                              <SelectValue placeholder="Năm kết thúc" />
                            </SelectTrigger>
                            <SelectContent>
                              {(() => {
                                const current = new Date().getFullYear();
                                const startY = Number(inlineEditData?.KHOAHOC.split('-')[0] || current);
                                const maxEnd = Math.min(startY + 7, current + 10);
                                return Array.from({ length: maxEnd - startY + 1 }).map((_, idx) => {
                                  const year = startY + idx;
                                  return <SelectItem key={year} value={String(year)}>{year}</SelectItem>;
                                });
                              })()}
                            </SelectContent>
                          </Select>
                        </div>
                        {validationErrors.KHOAHOC && (
                          <p className="text-xs text-red-500 mt-1">{validationErrors.KHOAHOC}</p>
                        )}
                      </TableCell>
                      <TableCell>
                        <Select
                          value={inlineEditData?.MAKHOA || ''}
                          onValueChange={(value) => handleInlineInputChange('MAKHOA', value)}
                          /* Cho phép sửa khoa cả khi editing row */
                        >
                          <SelectTrigger className={cn(
                            "w-full", 
                            validationErrors.MAKHOA && "border-red-500"
                          )}>
                            <SelectValue placeholder="Chọn khoa" />
                          </SelectTrigger>
                          <SelectContent>
                            {faculties.map(faculty => (
                              <SelectItem key={faculty.MAKHOA} value={faculty.MAKHOA}>
                                {`${faculty.TENKHOA} - ${faculty.MAKHOA}`}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        {validationErrors.MAKHOA && (
                          <p className="text-xs text-red-500 mt-1">{validationErrors.MAKHOA}</p>
                        )}
                      </TableCell>
                      <TableCell className="text-center">
                        {cls.SOSINHVIEN || 0}
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end space-x-1">
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={(e) => {
                              e.stopPropagation();
                              handleSaveEdit();
                            }}
                          >
                            <Check className="h-4 w-4 text-green-600" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={(e) => {
                              e.stopPropagation();
                              handleCancelEdit();
                            }}
                          >
                            <X className="h-4 w-4 text-red-600" />
                          </Button>
                        </div>
                      </TableCell>
                    </>
                  ) : (
                    <>
                      <TableCell>{cls.MALOP}</TableCell>
                      <TableCell>{cls.TENLOP}</TableCell>
                      <TableCell>{cls.KHOAHOC}</TableCell>
                      <TableCell>
                        {(() => {
                          const fac = faculties.find(f => f.MAKHOA === cls.MAKHOA);
                          if (!fac) return cls.MAKHOA;
                          return (
                            <div className="flex flex-col">
                              <span>{fac.TENKHOA}</span>
                              <span className="text-xs text-muted-foreground">{fac.MAKHOA}</span>
                            </div>
                          );
                        })()}
                      </TableCell>
                      <TableCell className="text-center">
                        <span className="font-medium">{cls.SOSINHVIEN || 0}</span>
                      </TableCell>
                      <TableCell className="text-right">
                        {canEdit && (
                          <div className="flex justify-end space-x-1">
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={(e) => {
                                e.stopPropagation();
                                handleEditClass(cls);
                              }}
                              disabled={!!editingId}
                            >
                              <Pencil className="h-4 w-4 text-blue-600" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={(e) => {
                                e.stopPropagation();
                                handleDeleteClass(cls.MALOP);
                              }}
                              disabled={!!editingId || (cls.SOSINHVIEN && cls.SOSINHVIEN > 0)}
                              title={(cls.SOSINHVIEN && cls.SOSINHVIEN > 0) ? 
                                "Không thể xóa lớp đã có sinh viên" : "Xóa lớp"}
                            >
                              <Trash2 className={cn(
                                "h-4 w-4", 
                                (cls.SOSINHVIEN && cls.SOSINHVIEN > 0) ? 
                                  "text-gray-400" : "text-red-600"
                              )} />
                            </Button>
                          </div>
                        )}
                      </TableCell>
                    </>
                  )}
                </TableRow>
              ))
            )}
            
            {/* New class row */}
            {editingId === 'new' && (
              <TableRow>
                <TableCell>
                  <Input
                    value={inlineEditData?.MALOP || ''}
                    onChange={(e) => handleInlineInputChange('MALOP', e.target.value)}
                    placeholder="Mã lớp"
                    className={validationErrors.MALOP ? "border-red-500" : ""}
                  />
                  {validationErrors.MALOP && (
                    <p className="text-xs text-red-500 mt-1">{validationErrors.MALOP}</p>
                  )}
                </TableCell>
                <TableCell>
                  <Input
                    value={inlineEditData?.TENLOP || ''}
                    onChange={(e) => handleInlineInputChange('TENLOP', e.target.value)}
                    placeholder="Tên lớp"
                    className={validationErrors.TENLOP ? "border-red-500" : ""}
                  />
                  {validationErrors.TENLOP && (
                    <p className="text-xs text-red-500 mt-1">{validationErrors.TENLOP}</p>
                  )}
                </TableCell>
                <TableCell>
                  {/* Year range selection for KHOAHOC */}
                  <div className="flex flex-col space-y-1">
                    {/* Start year */}
                    <Select
                      value={inlineEditData?.KHOAHOC.split('-')[0] || ''}
                      onValueChange={(value) => {
                        const endYear = inlineEditData?.KHOAHOC.split('-')[1] || String(Number(value) + 4);
                        handleInlineInputChange('KHOAHOC', `${value}-${endYear}`);
                      }}
                      disabled={editingId !== 'new' && Number(inlineEditData?.KHOAHOC.split('-')[0]) < new Date().getFullYear()}
                    >
                      <SelectTrigger className={cn('w-24', validationErrors.KHOAHOC && 'border-red-500')}>
                        <SelectValue placeholder="Entry" />
                      </SelectTrigger>
                      <SelectContent>
                        {(() => {
                          const current = new Date().getFullYear();
                          return Array.from({ length: 4 }).map((_, idx) => {
                            const year = current + idx;
                            return <SelectItem key={year} value={String(year)}>{year}</SelectItem>;
                          });
                        })()}
                      </SelectContent>
                    </Select>
                    <span className="self-center">-</span>
                    {/* End year */}
                    <Select
                      value={inlineEditData?.KHOAHOC.split('-')[1] || ''}
                      onValueChange={(value) => {
                        const startYear = inlineEditData?.KHOAHOC.split('-')[0] || String(Number(value) - 4);
                        handleInlineInputChange('KHOAHOC', `${startYear}-${value}`);
                      }}
                    >
                      <SelectTrigger className={cn('w-24', validationErrors.KHOAHOC && 'border-red-500')}>
                        <SelectValue placeholder="Graduated" />
                      </SelectTrigger>
                      <SelectContent>
                        {(() => {
                          const current = new Date().getFullYear();
                          const startY = Number(inlineEditData?.KHOAHOC.split('-')[0] || current);
                          const maxEnd = Math.min(startY + 7, current + 10);
                          return Array.from({ length: maxEnd - startY + 1 }).map((_, idx) => {
                            const year = startY + idx;
                            return <SelectItem key={year} value={String(year)}>{year}</SelectItem>;
                          });
                        })()}
                      </SelectContent>
                    </Select>
                  </div>
                  {validationErrors.KHOAHOC && (
                    <p className="text-xs text-red-500 mt-1">{validationErrors.KHOAHOC}</p>
                  )}
                </TableCell>
                <TableCell>
                  <Select
                    value={inlineEditData?.MAKHOA || ''}
                    onValueChange={(value) => handleInlineInputChange('MAKHOA', value)}
                  >
                    <SelectTrigger className={cn(
                      "w-full", 
                      validationErrors.MAKHOA && "border-red-500"
                    )}>
                      <SelectValue placeholder="Chọn khoa" />
                    </SelectTrigger>
                    <SelectContent>
                      {faculties.map(faculty => (
                        <SelectItem key={faculty.MAKHOA} value={faculty.MAKHOA}>
                          {`${faculty.TENKHOA} - ${faculty.MAKHOA}`}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  {validationErrors.MAKHOA && (
                    <p className="text-xs text-red-500 mt-1">{validationErrors.MAKHOA}</p>
                  )}
                </TableCell>
                <TableCell className="text-center">
                  <span className="text-muted-foreground">0</span>
                </TableCell>
                <TableCell className="text-right">
                  <div className="flex justify-end space-x-1">
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={(e) => {
                        e.stopPropagation();
                        handleSaveEdit();
                      }}
                    >
                      <Check className="h-4 w-4 text-green-600" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={(e) => {
                        e.stopPropagation();
                        handleCancelEdit();
                      }}
                    >
                      <X className="h-4 w-4 text-red-600" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
      
      {/* Pagination controls */}
      <div className="mt-2 flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <p className="text-sm text-muted-foreground">
            Hiển thị
          </p>
          <Select
            value={pageSize.toString()}
            onValueChange={handlePageSizeChange}
            disabled={isLoading}
          >
            <SelectTrigger className="h-8 w-16">
              <SelectValue placeholder={pageSize.toString()} />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="5">5</SelectItem>
              <SelectItem value="10">10</SelectItem>
              <SelectItem value="20">20</SelectItem>
              <SelectItem value="50">50</SelectItem>
            </SelectContent>
          </Select>
          <p className="text-sm text-muted-foreground">
            lớp mỗi trang
          </p>
        </div>
        
        <div className="flex items-center space-x-1">
          <Button
            variant="outline"
            size="icon"
            className="h-8 w-8"
            onClick={() => setCurrentPage(1)}
            disabled={currentPage === 1 || isLoading}
          >
            <SkipBack className="h-4 w-4" />
          </Button>
          <Button
            variant="outline"
            size="icon"
            className="h-8 w-8"
            onClick={() => setCurrentPage(currentPage - 1)}
            disabled={currentPage === 1 || isLoading}
          >
            <ChevronLeft className="h-4 w-4" />
          </Button>
          
          <span className="text-sm mx-2">
            {currentPage} / {totalPages()}
          </span>
          
          <Button
            variant="outline"
            size="icon"
            className="h-8 w-8"
            onClick={() => setCurrentPage(currentPage + 1)}
            disabled={currentPage === totalPages() || isLoading}
          >
            <ChevronRight className="h-4 w-4" />
          </Button>
          <Button
            variant="outline"
            size="icon"
            className="h-8 w-8"
            onClick={() => setCurrentPage(totalPages())}
            disabled={currentPage === totalPages() || isLoading}
          >
            <SkipForward className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Confirmation dialogs */}
      <Dialog open={confirmAction === 'save'} onOpenChange={() => setConfirmAction(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Lưu thay đổi</DialogTitle>
            <DialogDescription>
              Bạn có chắc chắn muốn lưu tất cả thay đổi vào cơ sở dữ liệu?
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmAction(null)}>Hủy</Button>
            <Button variant="default" onClick={handleConfirmSave}>Lưu thay đổi</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={confirmAction === 'reset'} onOpenChange={() => setConfirmAction(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Hủy thay đổi</DialogTitle>
            <DialogDescription>
              Bạn có chắc chắn muốn hủy tất cả thay đổi chưa lưu?
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmAction(null)}>Giữ thay đổi</Button>
            <Button variant="destructive" onClick={handleConfirmReset}>Hủy tất cả thay đổi</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={confirmAction === 'exit'} onOpenChange={() => setConfirmAction(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Hủy thêm mới</DialogTitle>
            <DialogDescription>
              Bạn có chắc chắn muốn hủy thêm lớp mới? Dữ liệu đã nhập sẽ bị mất.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmAction(null)}>Tiếp tục chỉnh sửa</Button>
            <Button variant="destructive" onClick={() => { resetChanges(); setConfirmAction(null); }}>
              Hủy thêm mới
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

/**
 * StudentsPanel component renders the right side of the split view
 */
function StudentsPanel({ canEdit, isFullscreen }: { canEdit: boolean; isFullscreen: boolean }) {
  const { toast } = useToast();
  const [isLoading, setIsLoading] = useState(false);
  const [confirmAction, setConfirmAction] = useState<'save' | 'exit' | 'reset' | 'delete' | null>(null);
  const [studentToDelete, setStudentToDelete] = useState<string | null>(null);
  const [studentIdExists, setStudentIdExists] = useState(false);
  const [editingStudentId, setEditingStudentId] = useState<string | null>(null); // Track which student is being edited

  // Access the class and student stores
  const { selectedClass } = useClassesStore();
  const {
    students,
    totalStudents,
    setCurrentClass,
    addStudent,
    editStudent,
    deleteStudent: storeDeleteStudent,
    setEditingStudent,
    editingStudent,
    updateEditingStudent,
    cancelEditing,
    undo,
    resetChanges,
    hasChanges,
    setSearchTerm,
    setSortField,
    toggleSortDirection,
    setPageSize,
    setCurrentPage,
    searchTerm,
    sortField,
    sortDirection,
    pageSize,
    currentPage,
    isLoading: isLoadingStudents,
    setLoading,
    fetchStudents,
    getVisibleStudents
  } = useStudentsStore();

  // When selected class changes, update the students store
  useEffect(() => {
    setCurrentClass(selectedClass);
  }, [selectedClass]);

  // Handle create/edit student
  const handleEditStudent = (student: Student | null = null) => {
    if (!canEdit) return;

    if (student) {
      setEditingStudentId(student.MASV); // Track which student is being edited
      setEditingStudent({ ...student });
    } else {
      setEditingStudentId(null); // Not editing an existing student
      
      // Calculate a default birth date (18 years ago)
      const defaultBirthDate = new Date();
      defaultBirthDate.setFullYear(defaultBirthDate.getFullYear() - 15);
      const formattedBirthDate = defaultBirthDate.toISOString().split('T')[0];
      
      // Create new student with default values
      const newStudent = {
        MASV: '',
        HO: '',
        TEN: '',
        MALOP: selectedClass?.MALOP || '',
        PHAI: false, // false = Nam, true = Nữ
        NGAYSINH: formattedBirthDate, // Default to 18 years ago
        DIACHI: '', // Empty address
        DANGHIHOC: false,
        isNew: true // Add this property to indicate a new student
      };
      setEditingStudent(newStudent);
    }
  };

  // Handle cancel editing
  const handleCancelEdit = () => {
    if (editingStudent?.isNew && (editingStudent.MASV.trim() || editingStudent.HO.trim() || editingStudent.TEN.trim())) {
      setConfirmAction('exit');
      return;
    }
    
    setEditingStudentId(null); // Clear editing ID
    cancelEditing();
  };

  // Handle field changes in student form
  const handleStudentFieldChange = (field: keyof Student, value: any) => {
    updateEditingStudent(field, value);
    
    // Check student ID uniqueness when adding new student
    if (field === 'MASV' && value.trim() && editingStudent?.isNew) {
      checkStudentExists(value, selectedClass?.MALOP || '')
        .then(exists => {
          setStudentIdExists(exists);
        });
    }
  };

  // Handle save student
  const handleSaveStudent = async () => {
    if (!editingStudent || !selectedClass) return;
    
    // Validate student data
    const validationError = validateStudent(editingStudent);
    if (validationError) {
      toast({
        title: "Lỗi dữ liệu",
        description: validationError,
        variant: "destructive"
      });
      return;
    }
    
    // Check if student ID exists
    if (editingStudent.isNew && studentIdExists) {
      toast({
        title: "Lỗi dữ liệu",
        description: "Mã sinh viên đã tồn tại",
        variant: "destructive"
      });
      return;
    }

    try {
      if (editingStudent.isNew) {
        // Add new student to store
        addStudent(editingStudent);
      } else {
        // Update existing student in store
        editStudent(editingStudent);
      }
      
      // Clear editing state
      setEditingStudentId(null);
      cancelEditing();
      
      toast({
        title: "Thành công",
        description: editingStudent.isNew ? "Đã thêm sinh viên vào bộ nhớ tạm" : "Đã cập nhật sinh viên trong bộ nhớ tạm"
      });
    } catch (error: any) {
      toast({
        title: "Lỗi",
        description: error.message,
        variant: "destructive"
      });
    }
  };

  // Handle delete student
  const handleDeleteStudent = (masv: string) => {
    if (!canEdit) return;
    
    // Directly mark for deletion in store (don't show confirmation)
    storeDeleteStudent(masv);
    
    toast({
      title: "Thành công", 
      description: "Đã đánh dấu sinh viên để xóa. Nhấn 'Ghi' để lưu thay đổi."
    });
  };
  
  // Handle undo last action
  const handleUndo = () => {
    undo();
    toast({
      title: "Hoàn tác", 
      description: "Đã hoàn tác thao tác gần nhất"
    });
  };
  
  // Handle save all changes
  const handleSaveChanges = async () => {
    setConfirmAction('save');
  };

  // Handle reset changes
  const handleResetChanges = () => {
    setConfirmAction('reset');
  };

  // Handle confirm save all changes
  const handleConfirmSave = async () => {
    setConfirmAction(null);
    setIsLoading(true);
    
    try {
      // Process each action in the stack - these should match what's in the students array
      // Added students
      const addedStudents = students.filter(s => s.isNew && !s.isDeleted);
      // Modified students
      const modifiedStudents = students.filter(s => s.isModified && !s.isNew && !s.isDeleted);
      // Deleted students
      const deletedStudents = students.filter(s => s.isDeleted);
      
      // Create added students
      for (const student of addedStudents) {
        try {
          // Create a clean copy for the API
          const apiStudent = {
            MASV: student.MASV,
            HO: student.HO,
            TEN: student.TEN,
            MALOP: student.MALOP,
            PHAI: student.PHAI, // Boolean (false=Nam, true=Nữ)
            NGAYSINH: student.NGAYSINH,
            DIACHI: student.DIACHI,
            DANGHIHOC: student.DANGHIHOC,
            PASSWORD: student.PASSWORD || '123456' // Always use default password if empty
          };
          
          await createStudent(apiStudent); // No need for type casting now
        } catch (error) {
          console.error('Error creating student:', error);
          throw error;
        }
      }
      
      // Update modified students
      for (const student of modifiedStudents) {
        try {
          // Create a clean copy for the API
          const apiStudent = {
            MASV: student.MASV,
            HO: student.HO,
            TEN: student.TEN,
            MALOP: student.MALOP,
            PHAI: student.PHAI, // Boolean (false=Nam, true=Nữ)
            NGAYSINH: student.NGAYSINH,
            DIACHI: student.DIACHI,
            DANGHIHOC: student.DANGHIHOC
          };
          
          await updateStudent(student.MASV, apiStudent); // No need for type casting now
        } catch (error) {
          console.error('Error updating student:', error);
          throw error;
        }
      }
      
      // Delete marked students
      for (const student of deletedStudents) {
        if (!student.isNew) { // Don't try to delete students that were added but not yet saved
          await deleteStudent(student.MASV);
        }
      }
      
      // Refresh data
      await fetchStudents();
      
      toast({
        title: "Thành công",
        description: "Đã lưu tất cả thay đổi"
      });
    } catch (error: any) {
      toast({
        title: "Lỗi",
        description: error.message || "Không thể lưu thay đổi",
        variant: "destructive"
      });
    } finally {
      setIsLoading(false);
    }
  };
  
  // Handle confirm reset
  const handleConfirmReset = () => {
    setConfirmAction(null);
    resetChanges();
    toast({
      title: "Đã hủy thay đổi", 
      description: "Đã hoàn tác tất cả thay đổi chưa lưu"
    });
  };

  // Handle search
  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(e.target.value);
  };

  // Handle sort
  const handleSortClick = (field: keyof Student) => {
    if (sortField === field) {
      toggleSortDirection();
    } else {
      setSortField(field);
    }
  };
  
  // Calculate pagination info
  const startItem = (currentPage - 1) * pageSize + 1;
  const endItem = Math.min(startItem + pageSize - 1, totalStudents);

  // Function to calculate the maximum allowed birth date (current date - 15 years)
  const calculateMaxBirthDate = (): string => {
    const date = new Date();
    date.setFullYear(date.getFullYear() - 15);
    return date.toISOString().split('T')[0]; // Format as YYYY-MM-DD
  };

  return (
    <div className="flex flex-col h-full">
      {/* Header and search */}
      <>
        <div className="flex justify-between items-center mb-2">
          <h2 className="text-lg font-semibold flex items-center gap-1">
            {selectedClass ? (
              <>
                <Users size={18} />
                Danh sách sinh viên - {selectedClass.TENLOP}
              </>
            ) : (
              "Chọn lớp để xem danh sách sinh viên"
            )}
          </h2>
          
          {/* Action buttons */}
          {selectedClass && canEdit && (
            <Button
              variant="outline"
              size="sm"
              onClick={() => handleEditStudent()}
              disabled={!!editingStudent || isLoading || isLoadingStudents}
            >
              <Plus className="h-4 w-4 mr-1" />
              Thêm sinh viên
            </Button>
          )}
        </div>
        
        {/* Search bar */}
        {selectedClass && (
          <div className="relative mb-2">
            <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Tìm kiếm sinh viên..."
              className="pl-8"
              value={searchTerm}
              onChange={handleSearch}
              disabled={isLoading || isLoadingStudents}
            />
          </div>
        )}
      </>
      
      {/* Student editing form - top form for adding new student */}
      {editingStudent && editingStudent.isNew && (
        <div className="border p-4 rounded-md mb-4 bg-muted/30">
          <div className="flex justify-between items-center mb-3">
            <h3 className="font-medium">Thêm sinh viên mới</h3>
            <Button
              variant="ghost"
              size="icon"
              onClick={handleCancelEdit}
            >
              <X className="h-4 w-4" />
            </Button>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            {/* MASV field - enabled for new students */}
            <div>
              <label className="text-sm font-medium mb-1 block">
                Mã sinh viên <span className="text-red-500">*</span>
              </label>
              <Input
                value={editingStudent.MASV}
                onChange={(e) => handleStudentFieldChange('MASV', e.target.value)}
                className={studentIdExists ? "border-red-500" : ""}
                autoComplete="off"
                data-form-type="other"
                name="student-id-code"
              />
              {studentIdExists && (
                <p className="text-xs text-red-500 mt-1">Mã sinh viên đã tồn tại</p>
              )}
            </div>
            
            {/* PHAI field */}
            <div>
              <label className="text-sm font-medium mb-1 block">
                Phái <span className="text-red-500">*</span>
              </label>
              <Select
                value={editingStudent.PHAI ? "true" : "false"}
                onValueChange={(value) => handleStudentFieldChange('PHAI', value === "true")}
              >
                <SelectTrigger data-form-type="other" name="student-gender-select">
                  <SelectValue placeholder="Chọn giới tính" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="false">Nam</SelectItem>
                  <SelectItem value="true">Nữ</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            {/* HO field */}
            <div>
              <label className="text-sm font-medium mb-1 block">
                Họ <span className="text-red-500">*</span>
              </label>
              <Input
                value={editingStudent.HO}
                onChange={(e) => handleStudentFieldChange('HO', e.target.value)}
                autoComplete="off"
                data-form-type="other"
                name="student-lastname-field"
              />
            </div>
            
            {/* NGAYSINH field */}
            <div>
              <label className="text-sm font-medium mb-1 block">
                Ngày sinh <span className="text-red-500">*</span>
              </label>
              <Input
                type="date"
                value={editingStudent.NGAYSINH}
                onChange={(e) => handleStudentFieldChange('NGAYSINH', e.target.value)}
                max={calculateMaxBirthDate()}
                autoComplete="off"
                data-form-type="other"
                name="student-birthdate-field"
              />
            </div>
            
            {/* TEN field */}
            <div>
              <label className="text-sm font-medium mb-1 block">
                Tên <span className="text-red-500">*</span>
              </label>
              <Input
                value={editingStudent.TEN}
                onChange={(e) => handleStudentFieldChange('TEN', e.target.value)}
                autoComplete="off"
                data-form-type="other"
                name="student-firstname-field"
              />
            </div>
            
            {/* DANGHIHOC field */}
            <div className="flex items-center space-x-2">
              <label className="text-sm font-medium">Đang nghỉ học</label>
              <input
                type="checkbox"
                checked={editingStudent.DANGHIHOC}
                onChange={(e) => handleStudentFieldChange('DANGHIHOC', e.target.checked)}
                className="h-4 w-4"
                data-form-type="other"
                name="student-status-field"
              />
            </div>
            
            {/* DIACHI field - full width */}
            <div className="md:col-span-2">
              <label className="text-sm font-medium mb-1 block">
                Địa chỉ <span className="text-red-500">*</span>
              </label>
              <Input
                value={editingStudent.DIACHI}
                onChange={(e) => handleStudentFieldChange('DIACHI', e.target.value)}
                autoComplete="off"
                data-form-type="other"
                name="student-address"
              />
            </div>

            {/* PASSWORD field - only for new students */}
            <div className="md:col-span-2">
              <label className="text-sm font-medium mb-1 block">
                Mật khẩu
              </label>
              <Input
                type="password"
                placeholder="Để trống sẽ dùng mật khẩu mặc định: 123456"
                value={editingStudent.PASSWORD || ''}
                onChange={(e) => handleStudentFieldChange('PASSWORD', e.target.value)}
                autoComplete="new-password"
                data-form-type="other"
                name="student-new-password"
              />
              <p className="text-xs text-muted-foreground mt-1">
                Mật khẩu mặc định là "123456" nếu không nhập
              </p>
            </div>
          </div>
          
          {/* Form actions */}
          <div className="flex justify-end space-x-2 mt-4">
            <Button
              variant="outline"
              size="sm"
              onClick={handleCancelEdit}
            >
              Hủy
            </Button>
            <Button
              variant="default"
              size="sm"
              onClick={handleSaveStudent}
              disabled={studentIdExists}
            >
              Thêm
            </Button>
          </div>
        </div>
      )}

      {/* Save changes bar - show when there are changes */}
      {hasChanges() && (
        <div className="bg-muted/30 p-2 rounded-md flex items-center justify-between mb-2">
          <span className="text-sm">
            Bạn có thay đổi chưa lưu
          </span>
          <div className="flex gap-2">
            <Button 
              variant="outline" 
              size="sm"
              onClick={handleUndo}
              disabled={isLoading || !hasChanges()}
              title="Hoàn tác thao tác gần nhất"
            >
              <RotateCcw className="h-4 w-4" />
            </Button>
            <Button 
              variant="outline" 
              size="sm"
              onClick={handleResetChanges}
              disabled={isLoading}
            >
              <XCircle className="h-4 w-4 mr-1" /> Hủy
            </Button>
            <Button 
              variant="default" 
              size="sm"
              onClick={handleSaveChanges}
              disabled={isLoading}
            >
              <Save className="h-4 w-4 mr-1" /> Ghi
            </Button>
          </div>
        </div>
      )}
      
      {/* Students table */}
      <div className="flex-1 overflow-y-auto">
        {!selectedClass ? (
          <div className="flex items-center justify-center h-full text-muted-foreground">
            Vui lòng chọn lớp từ danh sách bên trái
          </div>
        ) : isLoadingStudents ? (
          <div className="flex items-center justify-center h-full">
            Đang tải...
          </div>
        ) : students.length === 0 ? (
          <div className="flex items-center justify-center h-full text-muted-foreground">
            {searchTerm ? "Không tìm thấy sinh viên phù hợp" : "Lớp chưa có sinh viên nào"}
          </div>
        ) : (
          <Table>
            <TableHeader className="sticky top-0 bg-background">
              <TableRow>
                <TableHead className="w-1/6 cursor-pointer" onClick={() => handleSortClick('MASV')}>
                  <div className="flex items-center">
                    Mã SV
                    {sortField === 'MASV' && (
                      <ArrowUpDown className={cn(
                        "ml-1 h-4 w-4",
                        sortDirection === 'DESC' ? "transform rotate-180" : ""
                      )} />
                    )}
                  </div>
                </TableHead>
                <TableHead className="w-1/6 cursor-pointer" onClick={() => handleSortClick('HO')}>
                  <div className="flex items-center">
                    Họ
                    {sortField === 'HO' && (
                      <ArrowUpDown className={cn(
                        "ml-1 h-4 w-4",
                        sortDirection === 'DESC' ? "transform rotate-180" : ""
                      )} />
                    )}
                  </div>
                </TableHead>
                <TableHead className="w-1/6 cursor-pointer" onClick={() => handleSortClick('TEN')}>
                  <div className="flex items-center">
                    Tên
                    {sortField === 'TEN' && (
                      <ArrowUpDown className={cn(
                        "ml-1 h-4 w-4",
                        sortDirection === 'DESC' ? "transform rotate-180" : ""
                      )} />
                    )}
                  </div>
                </TableHead>
                <TableHead className="w-1/6 cursor-pointer" onClick={() => handleSortClick('PHAI')}>
                  <div className="flex items-center">
                    Phái
                    {sortField === 'PHAI' && (
                      <ArrowUpDown className={cn(
                        "ml-1 h-4 w-4",
                        sortDirection === 'DESC' ? "transform rotate-180" : ""
                      )} />
                    )}
                  </div>
                </TableHead>
                <TableHead className="w-1/6 cursor-pointer" onClick={() => handleSortClick('NGAYSINH')}>
                  <div className="flex items-center">
                    Ngày sinh
                    {sortField === 'NGAYSINH' && (
                      <ArrowUpDown className={cn(
                        "ml-1 h-4 w-4",
                        sortDirection === 'DESC' ? "transform rotate-180" : ""
                      )} />
                    )}
                  </div>
                </TableHead>
                {canEdit && (
                  <TableHead className="w-1/6 text-right">Thao tác</TableHead>
                )}
              </TableRow>
            </TableHeader>
            <TableBody>
              {students.map(student => (
                <>
                  <TableRow 
                    key={student.MASV}
                    className={cn(
                      student.isDeleted ? "text-red-600 bg-red-50" : 
                      student.isNew ? "text-green-600 bg-green-50" : 
                      student.isModified ? "text-yellow-600 bg-yellow-50" : 
                      student.DANGHIHOC ? "text-red-600" : ""
                    )}
                  >
                    <TableCell>{student.MASV}</TableCell>
                    <TableCell>{student.HO}</TableCell>
                    <TableCell>{student.TEN}</TableCell>
                    <TableCell>{student.PHAI ? 'Nữ' : 'Nam'}</TableCell>
                    <TableCell>
                      {new Date(student.NGAYSINH).toLocaleDateString('vi-VN')}
                    </TableCell>
                    {canEdit && (
                      <TableCell className="text-right">
                        <div className="flex justify-end space-x-1">
                          {!student.isDeleted && (
                            <>
                              <Button
                                variant="ghost"
                                size="icon"
                                onClick={() => handleEditStudent(student)}
                                disabled={!!editingStudent}
                              >
                                <Pencil className="h-4 w-4 text-blue-600" />
                              </Button>
                              
                              <Button
                                variant="ghost"
                                size="icon"
                                onClick={() => handleDeleteStudent(student.MASV)}
                                disabled={!!editingStudent}
                              >
                                <Trash2 className="h-4 w-4 text-red-600" />
                              </Button>
                            </>
                          )}
                        </div>
                      </TableCell>
                    )}
                  </TableRow>
                  
                  {/* Show edit form under the row being edited */}
                  {editingStudent && !editingStudent.isNew && editingStudentId === student.MASV && (
                    <TableRow>
                      <TableCell colSpan={canEdit ? 6 : 5}>
                        <div className="border p-4 rounded-md bg-muted/30">
                          <div className="flex justify-between items-center mb-3">
                            <h3 className="font-medium">Cập nhật thông tin sinh viên</h3>
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={handleCancelEdit}
                            >
                              <X className="h-4 w-4" />
                            </Button>
                          </div>
                          
                          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                            {/* MASV field - disabled for existing students */}
                            <div>
                              <label className="text-sm font-medium mb-1 block">
                                Mã sinh viên <span className="text-red-500">*</span>
                              </label>
                              <Input
                                value={editingStudent.MASV}
                                disabled={true}
                                className="bg-slate-100"
                                autoComplete="off"
                                data-form-type="other"
                                name="student-id-edit"
                              />
                            </div>
                            
                            {/* PHAI field */}
                            <div>
                              <label className="text-sm font-medium mb-1 block">
                                Phái <span className="text-red-500">*</span>
                              </label>
                              <Select
                                value={editingStudent.PHAI ? "true" : "false"}
                                onValueChange={(value) => handleStudentFieldChange('PHAI', value === "true")}
                              >
                                <SelectTrigger data-form-type="other" name="student-gender-edit">
                                  <SelectValue placeholder="Chọn giới tính" />
                                </SelectTrigger>
                                <SelectContent>
                                  <SelectItem value="false">Nam</SelectItem>
                                  <SelectItem value="true">Nữ</SelectItem>
                                </SelectContent>
                              </Select>
                            </div>
                            
                            {/* HO field */}
                            <div>
                              <label className="text-sm font-medium mb-1 block">
                                Họ <span className="text-red-500">*</span>
                              </label>
                              <Input
                                value={editingStudent.HO}
                                onChange={(e) => handleStudentFieldChange('HO', e.target.value)}
                                autoComplete="off"
                                data-form-type="other"
                                name="student-lastname-edit"
                              />
                            </div>
                            
                            {/* NGAYSINH field */}
                            <div>
                              <label className="text-sm font-medium mb-1 block">
                                Ngày sinh <span className="text-red-500">*</span>
                              </label>
                              <Input
                                type="date"
                                value={editingStudent.NGAYSINH}
                                onChange={(e) => handleStudentFieldChange('NGAYSINH', e.target.value)}
                                max={calculateMaxBirthDate()}
                                autoComplete="off"
                                data-form-type="other"
                                name="student-birthdate-edit"
                              />
                            </div>
                            
                            {/* TEN field */}
                            <div>
                              <label className="text-sm font-medium mb-1 block">
                                Tên <span className="text-red-500">*</span>
                              </label>
                              <Input
                                value={editingStudent.TEN}
                                onChange={(e) => handleStudentFieldChange('TEN', e.target.value)}
                                autoComplete="off"
                                data-form-type="other"
                                name="student-firstname-edit"
                              />
                            </div>
                            
                            {/* DANGHIHOC field */}
                            <div className="flex items-center space-x-2">
                              <label className="text-sm font-medium">Đang nghỉ học</label>
                              <input
                                type="checkbox"
                                checked={editingStudent.DANGHIHOC}
                                onChange={(e) => handleStudentFieldChange('DANGHIHOC', e.target.checked)}
                                className="h-4 w-4"
                                data-form-type="other"
                                name="student-status-edit"
                              />
                            </div>
                            
                            {/* DIACHI field - full width */}
                            <div className="md:col-span-2">
                              <label className="text-sm font-medium mb-1 block">
                                Địa chỉ <span className="text-red-500">*</span>
                              </label>
                              <Input
                                value={editingStudent.DIACHI}
                                onChange={(e) => handleStudentFieldChange('DIACHI', e.target.value)}
                                autoComplete="off"
                                data-form-type="other"
                                name="student-address"
                              />
                            </div>
                          </div>
                          
                          {/* Form actions */}
                          <div className="flex justify-end space-x-2 mt-4">
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={handleCancelEdit}
                            >
                              Hủy
                            </Button>
                            <Button
                              variant="default"
                              size="sm"
                              onClick={handleSaveStudent}
                            >
                              Cập nhật
                            </Button>
                          </div>
                        </div>
                      </TableCell>
                    </TableRow>
                  )}
                </>
              ))}
            </TableBody>
          </Table>
        )}
      </div>
      
      {/* Pagination information */}
      {selectedClass && totalStudents > 0 && (
        <div className="mt-2 flex items-center justify-between">
          <div className="text-sm text-muted-foreground">
            Hiển thị sinh viên {startItem}-{endItem} trên {totalStudents}
          </div>
          
          <div className="flex items-center space-x-1">
            <Button
              variant="outline"
              size="icon"
              className="h-8 w-8"
              onClick={() => setCurrentPage(1)}
              disabled={currentPage === 1 || isLoading || isLoadingStudents}
            >
              <SkipBack className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="icon"
              className="h-8 w-8"
              onClick={() => setCurrentPage(currentPage - 1)}
              disabled={currentPage === 1 || isLoading || isLoadingStudents}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            
            <span className="text-sm mx-2">
              {currentPage} / {Math.ceil(totalStudents / pageSize) || 1}
            </span>
            
            <Button
              variant="outline"
              size="icon"
              className="h-8 w-8"
              onClick={() => setCurrentPage(currentPage + 1)}
              disabled={endItem >= totalStudents || isLoading || isLoadingStudents}
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="icon"
              className="h-8 w-8"
              onClick={() => setCurrentPage(Math.ceil(totalStudents / pageSize))}
              disabled={endItem >= totalStudents || isLoading || isLoadingStudents}
            >
              <SkipForward className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}
      
      {/* Confirmation dialogs */}
      <Dialog open={confirmAction === 'exit'} onOpenChange={() => setConfirmAction(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Hủy thêm mới</DialogTitle>
            <DialogDescription>
              Bạn có chắc chắn muốn hủy thêm sinh viên mới? Dữ liệu đã nhập sẽ bị mất.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmAction(null)}>Tiếp tục chỉnh sửa</Button>
            <Button variant="destructive" onClick={() => { cancelEditing(); setConfirmAction(null); }}>
              Hủy thêm mới
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={confirmAction === 'save'} onOpenChange={() => setConfirmAction(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Lưu thay đổi</DialogTitle>
            <DialogDescription>
              Bạn có chắc chắn muốn lưu tất cả thay đổi vào cơ sở dữ liệu?
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmAction(null)}>Hủy</Button>
            <Button variant="default" onClick={handleConfirmSave}>Lưu thay đổi</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={confirmAction === 'reset'} onOpenChange={() => setConfirmAction(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Hủy thay đổi</DialogTitle>
            <DialogDescription>
              Bạn có chắc chắn muốn hủy tất cả thay đổi chưa lưu?
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmAction(null)}>Giữ thay đổi</Button>
            <Button variant="destructive" onClick={handleConfirmReset}>Hủy tất cả thay đổi</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
} 