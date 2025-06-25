/**
 * Subject Management Page
 * Allows viewing, creating, editing and deleting subjects
 * Access: PGV (full access), KHOA (view only)
 */
import { useEffect, useState } from 'react';
import { Navigate } from 'react-router-dom';
import { 
  Subject, 
  fetchSubjects, 
  upsertSubject, 
  deleteSubject, 
  bulkUpsertSubjects, 
  validateSubject,
  SubjectWithMeta,
  checkSubjectCodeExists,
  checkSubjectNameExists
} from '@/services/subjectService';
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
import { useToast } from '@/components/ui/use-toast';
import { useAuthStore } from '@/store/use-auth-store';
import { useSubjectsStore } from '@/store/use-subjects-store';
import { UserRole } from '@/types';
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
  Check
} from 'lucide-react';
import { cn } from '@/lib/utils';
import {
  Table,
  TableHeader,
  TableBody,
  TableHead,
  TableRow,
  TableCell,
} from '@/components/ui/table';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';

/**
 * Main subject management page component
 */
export default function SubjectsPage() {
  const { user } = useAuthStore();
  const { toast } = useToast();

  // UI state
  const [editingId, setEditingId] = useState<string | null>(null);
  const [inlineEditData, setInlineEditData] = useState<Subject | null>(null);
  const [validationErrors, setValidationErrors] = useState<{[key: string]: string}>({});
  const [confirmAction, setConfirmAction] = useState<'save' | 'exit' | 'reset' | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [codeExists, setCodeExists] = useState(false);
  const [nameExists, setNameExists] = useState(false);

  // Access the global subjects store
  const { 
    subjects, 
    originalSubjects,
    actionsStack,
    setSubjects,
    addSubject,
    editSubject: storeEditSubject,
    deleteSubject: storeDeleteSubject,
    undo,
    resetChanges,
    saveChanges,
    hasChanges,
    setSearchTerm,
    setSortField,
    toggleSortDirection,
    setPageSize,
    setCurrentPage,
    filteredSubjects,
    paginatedSubjects,
    totalPages,
    currentPage,
    pageSize,
    sortField,
    sortDirection,
    searchTerm
  } = useSubjectsStore();

  // Permission checks
  const role = user?.role;
  const canView = role === UserRole.PGV || role === UserRole.KHOA;
  const canEdit = role === UserRole.PGV;

  // Redirect if no permission
  if (!canView) {
    return <Navigate to="/dashboard" replace />;
  }

  // Load subjects data on component mount
  useEffect(() => {
    loadSubjects();
  }, []);

  // Check for duplicate code and name when adding new subject
  useEffect(() => {
    if (inlineEditData && editingId === 'new') {
      const checkCode = async () => {
        if (inlineEditData.MAMH.trim()) {
          const exists = await checkSubjectCodeExists(inlineEditData.MAMH);
          setCodeExists(exists);
          if (exists) {
            setValidationErrors(prev => ({
              ...prev,
              MAMH: 'Mã môn học đã tồn tại'
            }));
          } else {
            setValidationErrors(prev => {
              const { MAMH, ...rest } = prev;
              return rest;
            });
          }
        }
      };
      
      const checkName = async () => {
        if (inlineEditData.TENMH.trim()) {
          const exists = await checkSubjectNameExists(inlineEditData.TENMH);
          setNameExists(exists);
          if (exists) {
            setValidationErrors(prev => ({
              ...prev,
              TENMH: 'Tên môn học đã tồn tại'
            }));
          } else {
            setValidationErrors(prev => {
              const { TENMH, ...rest } = prev;
              return rest;
            });
          }
        }
      };
      
      // Run validation checks
      checkCode();
      checkName();
    }
  }, [inlineEditData?.MAMH, inlineEditData?.TENMH, editingId]);

  // Load subjects from API
  const loadSubjects = async () => {
    try {
      setIsLoading(true);
      const data = await fetchSubjects();
      setSubjects(data);
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

  // Subject management handlers
  const handleAddSubject = () => {
    // Only PGV can add subjects, and only when not already editing
    if (!canEdit || editingId) return;
    
    // Create a new empty subject
    const newSubject: Subject = {
      // DB-style keys
      MAMH: '',
      TENMH: '',
      SOTIET_LT: 15, // Default value
      SOTIET_TH: 0,  // Default value
      IS_LINKED: false,

      // camelCase aliases
      mamh: '',
      tenmh: '',
      sotiet_lt: 15,
      sotiet_th: 0,
    };
    
    setEditingId('new');
    setInlineEditData(newSubject);
    setValidationErrors({});
  };

  const handleEditSubject = (subject: Subject) => {
    // Only PGV can edit subjects, and only when not already editing
    if (!canEdit || editingId) return;
    
    setEditingId(subject.MAMH);
    setInlineEditData({...subject});
    setValidationErrors({});
  };

  const handleCancelEdit = () => {
    // If there are changes, show confirmation dialog
    if (
      inlineEditData && 
      (inlineEditData.MAMH.trim() || inlineEditData.TENMH.trim()) && 
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
    const error = validateSubject(inlineEditData);
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
    
    // Handle new subject
    if (editingId === 'new') {
      // Add to subjects store
      addSubject(inlineEditData);
      
      // Find the page containing the new subject after adding
      const allFiltered = [...filteredSubjects(), inlineEditData];
      const targetIndex = allFiltered.findIndex(s => s.MAMH === inlineEditData.MAMH);
      const targetPage = Math.floor(targetIndex / pageSize) + 1;
      if (targetPage !== currentPage) {
        setCurrentPage(targetPage);
      }
    } else {
      // Edit existing subject
      storeEditSubject(inlineEditData);
    }
    
    // Clear edit state
    setEditingId(null);
    setInlineEditData(null);
    setValidationErrors({});
    setCodeExists(false);
    setNameExists(false);
    
    toast({
      title: "Thành công",
      description: editingId === 'new' ? "Đã thêm môn học mới" : "Đã cập nhật môn học",
    });
  };

  const handleDeleteSubject = (mamh: string) => {
    // Only PGV can delete subjects
    if (!canEdit) return;
    
    // Find the subject
    const subject = subjects.find(s => s.MAMH === mamh);
    if (!subject) return;

    // Cannot delete subjects that are linked to credit classes
    if (subject.IS_LINKED) {
      toast({
        title: "Không thể xóa",
        description: "Môn học này đã được sử dụng trong lớp tín chỉ",
        variant: "destructive"
      });
      return;
    }

    // Delete in store
    storeDeleteSubject(mamh);
    
    toast({
      title: "Đã xóa",
      description: "Môn học sẽ bị xóa sau khi lưu thay đổi",
    });
  };

  const handleInlineInputChange = (field: keyof Subject, value: string | number) => {
    if (!inlineEditData) return;
    
    // Update the inline edit data
    setInlineEditData(prev => {
      if (!prev) return prev;
      return { ...prev, [field]: value };
    });
    
    // Clear validation error for this field if any
    if (validationErrors[field]) {
      setValidationErrors(prev => {
        const { [field]: _, ...rest } = prev;
        return rest;
      });
    }
  };

  const handleConfirmSave = async () => {
    setConfirmAction(null);
    
    try {
      setIsLoading(true);
      
      // Get changes from the store
      const { toSave, toDelete } = saveChanges();
      
      // Process deletions
      for (const mamh of toDelete) {
        await deleteSubject(mamh);
      }
      
      // Process additions/updates
      if (toSave.length > 0) {
      await bulkUpsertSubjects(toSave);
      }
      
      // Refresh data from server
      await loadSubjects();
      
      toast({
        title: "Thành công",
        description: "Tất cả thay đổi đã được lưu",
      });
    } catch (error: any) {
      toast({
        title: "Lỗi khi lưu thay đổi",
        description: error.message,
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleConfirmExit = () => {
    setConfirmAction(null);
    setEditingId(null);
    setInlineEditData(null);
    setValidationErrors({});
  };

  const handleConfirmReset = () => {
    setConfirmAction(null);
    resetChanges();
    toast({
      title: "Đã huỷ thay đổi",
      description: "Tất cả thay đổi đã được huỷ bỏ",
    });
  };

  const handleUndo = () => {
    undo();
    toast({
      title: "Đã hoàn tác",
      description: "Thao tác cuối cùng đã được hoàn tác",
    });
  };

  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(e.target.value);
  };

  const handleSortClick = (field: keyof Subject) => {
    if (sortField === field) {
      toggleSortDirection();
    } else {
      setSortField(field);
    }
  };

  const handlePageSizeChange = (value: string) => {
    setPageSize(Number(value));
  };

  return (
    <div className="container py-6 space-y-6">
      <div className="flex items-center justify-between">
      <h1 className="text-2xl font-bold">Quản lý môn học</h1>

        {canEdit && (
          <div className="flex items-center gap-2">
            {hasChanges() && (
              <>
                <Button 
                  variant="outline" 
                  size="sm" 
                  onClick={() => setConfirmAction('reset')}
                  disabled={isLoading}
                >
                  <RotateCcw className="h-4 w-4 mr-1" />
                  Huỷ thay đổi
                </Button>
                
                <Button 
                  variant="outline" 
                  size="sm" 
                  onClick={handleUndo}
                  disabled={actionsStack.length === 0 || isLoading}
                >
                  <RotateCcw className="h-4 w-4 mr-1" />
                  Hoàn tác
                </Button>
                
                <Button 
                  variant="default" 
                  size="sm" 
                  onClick={() => setConfirmAction('save')}
                  disabled={!hasChanges() || isLoading}
                >
                  <Save className="h-4 w-4 mr-1" />
                  Lưu thay đổi
                </Button>
              </>
            )}
            
            <Button 
              variant="default" 
              size="sm" 
              onClick={handleAddSubject}
              disabled={!!editingId || isLoading}
            >
              <Plus className="h-4 w-4 mr-1" />
              Thêm môn học
            </Button>
          </div>
        )}
      </div>

      {/* Search and filters */}
      <div className="flex flex-col sm:flex-row gap-3 items-center">
        <div className="relative flex-1">
          <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Tìm kiếm theo mã hoặc tên môn học..."
            className="pl-8"
            value={searchTerm}
            onChange={handleSearch}
          />
        </div>
        
        <div className="flex items-center gap-2">
          <span className="text-sm text-muted-foreground whitespace-nowrap">
            Hiển thị:
          </span>
          <Select
            value={pageSize.toString()}
            onValueChange={handlePageSizeChange}
          >
            <SelectTrigger className="w-20">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="5">5</SelectItem>
              <SelectItem value="10">10</SelectItem>
              <SelectItem value="20">20</SelectItem>
              <SelectItem value="50">50</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Subjects table */}
      <div className="border rounded-md">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="w-[120px]" onClick={() => handleSortClick('MAMH')}>
                <div className="flex items-center cursor-pointer">
                  <span>Mã MH</span>
                  <ArrowUpDown className={cn(
                    "ml-1 h-4 w-4", 
                    sortField === 'MAMH' ? 'opacity-100' : 'opacity-50'
                  )} />
                </div>
              </TableHead>
              
              <TableHead onClick={() => handleSortClick('TENMH')}>
                <div className="flex items-center cursor-pointer">
                  <span>Tên môn học</span>
                  <ArrowUpDown className={cn(
                    "ml-1 h-4 w-4", 
                    sortField === 'TENMH' ? 'opacity-100' : 'opacity-50'
                  )} />
                </div>
              </TableHead>
              
              <TableHead className="w-[120px] text-center" onClick={() => handleSortClick('SOTIET_LT')}>
                <div className="flex items-center justify-center cursor-pointer">
                  <span>Số tiết LT</span>
                  <ArrowUpDown className={cn(
                    "ml-1 h-4 w-4", 
                    sortField === 'SOTIET_LT' ? 'opacity-100' : 'opacity-50'
                  )} />
                </div>
              </TableHead>
              
              <TableHead className="w-[120px] text-center" onClick={() => handleSortClick('SOTIET_TH')}>
                <div className="flex items-center justify-center cursor-pointer">
                  <span>Số tiết TH</span>
                  <ArrowUpDown className={cn(
                    "ml-1 h-4 w-4", 
                    sortField === 'SOTIET_TH' ? 'opacity-100' : 'opacity-50'
                  )} />
                </div>
              </TableHead>
              
              {canEdit && (
                <TableHead className="w-[100px] text-center">
                  Thao tác
                </TableHead>
              )}
            </TableRow>
          </TableHeader>
          
          <TableBody>
            {/* Show loading state */}
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={canEdit ? 5 : 4} className="text-center py-8">
                  Đang tải dữ liệu...
                </TableCell>
              </TableRow>
            ) : (
              /* Empty state */
              paginatedSubjects().length === 0 && (
              <TableRow>
                  <TableCell colSpan={canEdit ? 5 : 4} className="text-center py-8">
                    {searchTerm 
                      ? "Không tìm thấy môn học phù hợp với từ khóa tìm kiếm." 
                      : "Chưa có môn học nào. Hãy thêm môn học mới."}
                  </TableCell>
                </TableRow>
              )
            )}
            
            {/* New subject row (when adding) */}
            {editingId === 'new' && inlineEditData && (
              <TableRow className="bg-accent/30">
                <TableCell>
                  <Input 
                    value={inlineEditData.MAMH} 
                    onChange={(e) => handleInlineInputChange('MAMH', e.target.value)}
                    className={validationErrors.MAMH ? "border-destructive" : ""}
                    placeholder="Mã"
                    maxLength={10}
                  />
                  {validationErrors.MAMH && (
                    <p className="text-xs text-destructive mt-1">{validationErrors.MAMH}</p>
                  )}
                </TableCell>
                
                <TableCell>
                  <Input 
                    value={inlineEditData.TENMH} 
                    onChange={(e) => handleInlineInputChange('TENMH', e.target.value)}
                    className={validationErrors.TENMH ? "border-destructive" : ""}
                    placeholder="Tên môn học"
                    maxLength={50}
                  />
                  {validationErrors.TENMH && (
                    <p className="text-xs text-destructive mt-1">{validationErrors.TENMH}</p>
                  )}
                </TableCell>
                
                <TableCell className="text-center">
                  <Input 
                    type="number" 
                    min={0}
                    value={inlineEditData.SOTIET_LT} 
                    onChange={(e) => handleInlineInputChange('SOTIET_LT', parseInt(e.target.value) || 0)}
                    className="text-center"
                  />
                </TableCell>
                
                <TableCell className="text-center">
                  <Input 
                    type="number"
                    min={0}
                    value={inlineEditData.SOTIET_TH} 
                    onChange={(e) => handleInlineInputChange('SOTIET_TH', parseInt(e.target.value) || 0)}
                    className="text-center"
                  />
                </TableCell>
                
                <TableCell>
                  <div className="flex justify-center gap-1">
                    <Button 
                      variant="ghost" 
                      size="sm"
                      onClick={handleSaveEdit}
                      disabled={
                        !!validationErrors.MAMH || 
                        !!validationErrors.TENMH ||
                        !inlineEditData.MAMH.trim() ||
                        !inlineEditData.TENMH.trim()
                      }
                    >
                      <Check className="h-4 w-4 text-green-600" />
                    </Button>
                    <Button variant="ghost" size="sm" onClick={handleCancelEdit}>
                      <X className="h-4 w-4 text-destructive" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            )}
            
            {/* Subject rows */}
            {!isLoading && paginatedSubjects().map(subject => {
              // Check if currently editing this subject
              const isEditing = editingId === subject.MAMH;
              
              return (
                <TableRow 
                  key={subject.MAMH}
                  className={cn(
                    subject.isNew && "bg-green-50 dark:bg-green-950/20",
                    subject.isModified && "bg-yellow-50 dark:bg-yellow-950/20",
                    subject.isDeleted && "bg-red-50 dark:bg-red-950/20",
                    isEditing && "bg-accent/30"
                  )}
                >
                  {/* Subject code */}
                  <TableCell className={subject.isDeleted ? "line-through opacity-70" : ""}>
                    {isEditing ? (
                      <div 
                        className="inline-block w-full" 
                        style={{ cursor: 'not-allowed' }}
                        title="Không thể thay đổi mã môn học sau khi đã tạo"
                      >
                        <Input
                          value={inlineEditData?.MAMH || ''}
                          onChange={(e) => handleInlineInputChange('MAMH', e.target.value)}
                          disabled={true} // Can't change primary key
                          className="bg-muted"
                        />
                      </div>
                    ) : (
                      subject.MAMH
                      )}
                    </TableCell>
                  
                  {/* Subject name */}
                  <TableCell className={subject.isDeleted ? "line-through opacity-70" : ""}>
                    {isEditing ? (
                      <Input
                        value={inlineEditData?.TENMH || ''}
                        onChange={(e) => handleInlineInputChange('TENMH', e.target.value)}
                        className={validationErrors.TENMH ? "border-destructive" : ""}
                        maxLength={50}
                      />
                    ) : (
                      subject.TENMH
                      )}
                    </TableCell>
                  
                  {/* Theory hours */}
                    <TableCell className={cn("text-center", subject.isDeleted ? "line-through opacity-70" : "")}>
                    {isEditing ? (
                      <Input
                        type="number"
                        min={0}
                        value={inlineEditData?.SOTIET_LT || 0}
                        onChange={(e) => handleInlineInputChange('SOTIET_LT', parseInt(e.target.value) || 0)}
                        className="text-center"
                      />
                    ) : (
                      subject.SOTIET_LT
                    )}
                    </TableCell>
                  
                  {/* Practice hours */}
                    <TableCell className={cn("text-center", subject.isDeleted ? "line-through opacity-70" : "")}>
                    {isEditing ? (
                      <Input
                        type="number"
                        min={0}
                        value={inlineEditData?.SOTIET_TH || 0}
                        onChange={(e) => handleInlineInputChange('SOTIET_TH', parseInt(e.target.value) || 0)}
                        className="text-center"
                      />
                    ) : (
                      subject.SOTIET_TH
                    )}
                    </TableCell>
                  
                  {/* Actions */}
                    {canEdit && (
                    <TableCell>
                      {isEditing ? (
                        <div className="flex justify-center gap-1">
                          <Button 
                            variant="ghost"
                            size="sm" 
                            onClick={handleSaveEdit}
                            disabled={
                              !!validationErrors.MAMH || 
                              !!validationErrors.TENMH ||
                              !inlineEditData?.MAMH.trim() ||
                              !inlineEditData?.TENMH.trim()
                            }
                          >
                            <Check className="h-4 w-4 text-green-600" />
                          </Button>
                          <Button variant="ghost" size="sm" onClick={handleCancelEdit}>
                            <X className="h-4 w-4 text-destructive" />
                          </Button>
                        </div>
                      ) : (
                          <div className="flex justify-center gap-1">
                            {subject.isDeleted ? (
                              <span className="text-xs text-destructive">Đã đánh dấu xoá</span>
                            ) : (
                              <>
                                {/* Edit button with wrapper for tooltip and cursor */}
                                <div 
                                  className="inline-block" 
                                  style={!!editingId || isLoading ? { cursor: 'not-allowed' } : undefined}
                                  title={!!editingId ? "Đang chỉnh sửa một bản ghi khác" : isLoading ? "Đang tải dữ liệu" : "Chỉnh sửa môn học"}
                                >
                                  <Button 
                                    variant="ghost"
                                    size="sm" 
                                    onClick={() => handleEditSubject(subject)}
                                    disabled={!!editingId || isLoading}
                                    className={!!editingId || isLoading ? "opacity-50" : ""}
                                  >
                                    <Pencil className="h-4 w-4" />
                                  </Button>
                                </div>
                                {/* Delete button with wrapper for tooltip and cursor */}
                                <div 
                                  className="inline-block" 
                                  style={subject.IS_LINKED ? { cursor: 'not-allowed' } : undefined}
                                  title={subject.IS_LINKED ? "Không thể xóa môn học đã liên kết với lớp tín chỉ" : "Xóa môn học"}
                                >
                                  <Button 
                                    variant="ghost" 
                                    size="sm" 
                                    onClick={() => handleDeleteSubject(subject.MAMH)}
                                    disabled={!!editingId || isLoading || subject.IS_LINKED}
                                    className={subject.IS_LINKED ? "opacity-50" : ""}
                                  >
                                    <Trash2 className="h-4 w-4 text-destructive" />
                                  </Button>
                                </div>
                              </>
                            )}
                          </div>
                        )}
                          </TableCell>
                    )}
                  </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </div>

      {/* Pagination */}
      {!isLoading && totalPages() > 1 && (
        <div className="flex justify-center gap-1 mt-4">
          <Button
            variant="outline"
            size="icon"
            onClick={() => setCurrentPage(1)}
            disabled={currentPage === 1}
          >
            <SkipBack className="h-4 w-4" />
          </Button>
          <Button
            variant="outline"
            size="icon"
            onClick={() => setCurrentPage(currentPage - 1)}
            disabled={currentPage === 1}
          >
            <ChevronLeft className="h-4 w-4" />
          </Button>
          
          <span className="mx-2 flex items-center">
            Trang {currentPage} / {totalPages()}
          </span>
          
          <Button
            variant="outline"
            size="icon"
            onClick={() => setCurrentPage(currentPage + 1)}
            disabled={currentPage === totalPages()}
          >
            <ChevronRight className="h-4 w-4" />
          </Button>
          <Button
            variant="outline"
            size="icon"
            onClick={() => setCurrentPage(totalPages())}
            disabled={currentPage === totalPages()}
          >
            <SkipForward className="h-4 w-4" />
          </Button>
        </div>
      )}

      {/* Confirmation dialog for save changes */}
      <Dialog open={confirmAction === 'save'} onOpenChange={() => setConfirmAction(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Xác nhận lưu thay đổi</DialogTitle>
            <DialogDescription>
              Bạn có chắc chắn muốn lưu tất cả thay đổi không? Hành động này không thể hoàn tác sau khi đã lưu.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmAction(null)}>Hủy</Button>
            <Button onClick={handleConfirmSave} disabled={isLoading}>
              {isLoading ? "Đang lưu..." : "Xác nhận"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Confirmation dialog for exit editing */}
      <Dialog open={confirmAction === 'exit'} onOpenChange={() => setConfirmAction(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Hủy thay đổi</DialogTitle>
            <DialogDescription>
              Bạn có chắc chắn muốn hủy các thay đổi đang thực hiện? Dữ liệu đã nhập sẽ bị mất.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmAction(null)}>Tiếp tục chỉnh sửa</Button>
            <Button variant="destructive" onClick={handleConfirmExit}>Hủy thay đổi</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Confirmation dialog for reset changes */}
      <Dialog open={confirmAction === 'reset'} onOpenChange={() => setConfirmAction(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Huỷ tất cả thay đổi</DialogTitle>
            <DialogDescription>
              Bạn có chắc chắn muốn huỷ tất cả thay đổi đã thực hiện? Thao tác này sẽ khôi phục lại trạng thái ban đầu và không thể hoàn tác.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmAction(null)}>Giữ thay đổi</Button>
            <Button variant="destructive" onClick={handleConfirmReset}>Huỷ tất cả thay đổi</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
} 