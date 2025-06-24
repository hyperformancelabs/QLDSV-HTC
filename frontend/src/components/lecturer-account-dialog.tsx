import React, { useState, useEffect } from 'react';
import { X, Loader2, Eye, EyeOff } from 'lucide-react';
import { useToast } from '@/components/ui/use-toast';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { ComboboxInput, ComboboxOption } from '@/components/ui/combobox-input';
import { LecturerAccount } from '@/types';
import { searchLecturers } from '@/services/lecturerAccountService';

interface LecturerAccountDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onCreateAccount: (data: {
    loginname: string;
    password: string;
    userid: string;
    role: 'pgv_role' | 'khoa_role';
  }) => Promise<void>;
  onDeleteAccount?: (magv: string) => Promise<void>;
  selectedLecturer?: LecturerAccount | null;
  mode: 'create' | 'edit';
}

// Default password for new accounts
const DEFAULT_PASSWORD = 'Gv@123456';

export function LecturerAccountDialog({
  open,
  onOpenChange,
  onCreateAccount,
  onDeleteAccount,
  selectedLecturer,
  mode,
}: LecturerAccountDialogProps) {
  // Form state
  const [formData, setFormData] = useState({
    loginname: '',
    password: DEFAULT_PASSWORD,
    userid: '',
    role: 'khoa_role' as 'pgv_role' | 'khoa_role',
  });

  // Lecturer search state
  const [searchTerm, setSearchTerm] = useState('');
  const [lecturerOptions, setLecturerOptions] = useState<ComboboxOption[]>([]);
  const [selectedLecturerId, setSelectedLecturerId] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [isLecturerPreselected, setIsLecturerPreselected] = useState(false);
  
  const { toast } = useToast();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  // Reset form when dialog opens/closes or mode changes
  useEffect(() => {
    if (open) {
      // Check if lecturer is pre-selected from action column (when mode is 'create' with selectedLecturer)
      // In this case, it means we're coming from the action column
      if (selectedLecturer && mode === 'create') {
        setFormData({
          loginname: `${selectedLecturer.MAGV}_LOGIN`,
          password: DEFAULT_PASSWORD,
          userid: selectedLecturer.MAGV || '',
          role: 'khoa_role',
        });
        setSelectedLecturerId(selectedLecturer.MAGV);
        setSearchTerm(`${selectedLecturer.HO} ${selectedLecturer.TEN}`);
        setIsLecturerPreselected(true); // Mark as pre-selected to make field readonly
      } else if (selectedLecturer && mode === 'edit') {
        // Edit mode (has a pre-selected lecturer with account)
        setFormData({
          loginname: selectedLecturer.LoginName || '',
          password: DEFAULT_PASSWORD,
          userid: selectedLecturer.MAGV || '',
          role: (selectedLecturer.Role as 'pgv_role' | 'khoa_role') || 'khoa_role',
        });
        setSelectedLecturerId(selectedLecturer.MAGV);
        setSearchTerm(`${selectedLecturer.HO} ${selectedLecturer.TEN}`);
        setIsLecturerPreselected(true);
      } else {
        // Regular "Create Account" button click - no pre-selection
        setFormData({
          loginname: '',
          password: DEFAULT_PASSWORD,
          userid: '',
          role: 'khoa_role',
        });
        setSelectedLecturerId('');
        setSearchTerm('');
        setIsLecturerPreselected(false);
      }
      
      // Load initial suggestions
      searchLecturersByName('');
    }
  }, [open, selectedLecturer, mode]);

  // Search lecturers by name
  const searchLecturersByName = async (query: string) => {
    setIsSearching(true);
    try {
      const lecturers = await searchLecturers(query);
      
      // Filter out lecturers who already have accounts
      const availableLecturers = lecturers.filter(lecturer => !lecturer.HasLogin);
      
      // Handle duplicate names by including ID in label
      const nameCount: Record<string, number> = {};
      
      // First count occurrences of each name
      availableLecturers.forEach(lecturer => {
        const fullName = `${lecturer.HO} ${lecturer.TEN}`.trim();
        nameCount[fullName] = (nameCount[fullName] || 0) + 1;
      });
      
      // Then format options with ID suffix for duplicates
      const options = availableLecturers.map(lecturer => {
        const fullName = `${lecturer.HO} ${lecturer.TEN}`.trim();
        const displayName = nameCount[fullName] > 1 
          ? `${fullName} (${lecturer.MAGV})` 
          : fullName;
          
        return {
          label: displayName,
          value: lecturer.MAGV,
          description: `Khoa: ${lecturer.TENKHOA}`
        };
      });
      
      setLecturerOptions(options);
    } catch (error) {
      console.error('Error searching lecturers:', error);
      toast({
        title: 'Lỗi tìm kiếm',
        description: 'Không thể tìm kiếm giảng viên',
        variant: 'destructive',
      });
    } finally {
      setIsSearching(false);
    }
  };

  // Handle search input change
  const handleSearchChange = (value: string) => {
    setSearchTerm(value);
    searchLecturersByName(value);
  };

  // Handle lecturer selection
  const handleLecturerSelect = (lecturerId: string) => {
    setSelectedLecturerId(lecturerId);
    
    // Auto-generate username and fill in ID
    setFormData(prev => ({
      ...prev,
      userid: lecturerId,
      loginname: lecturerId + '_LOGIN',
    }));
  };

  // Handle form input changes
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  // Handle role selection
  const handleRoleChange = (value: string) => {
    setFormData(prev => ({ ...prev, role: value as 'pgv_role' | 'khoa_role' }));
  };

  // Toggle password visibility
  const togglePasswordVisibility = () => {
    setShowPassword(!showPassword);
  };

  // Handle form submission
  const handleSubmit = async () => {
    if (!formData.userid || !formData.loginname || !formData.password) {
      toast({
        title: 'Thông tin không đầy đủ',
        description: 'Vui lòng chọn giảng viên và điền đầy đủ thông tin tài khoản',
        variant: 'destructive',
      });
      return;
    }
    
    setIsSubmitting(true);
    try {
      await onCreateAccount(formData);
      onOpenChange(false);
      toast({
        title: 'Thành công',
        description: 'Đã tạo tài khoản thành công',
      });
    } catch (error) {
      // Error is handled by parent component
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handle account deletion
  const handleDelete = async () => {
    if (!selectedLecturer || !onDeleteAccount) return;
    
    setIsDeleting(true);
    try {
      await onDeleteAccount(selectedLecturer.MAGV);
      onOpenChange(false);
    } catch (error) {
      // Error is handled by parent component
    } finally {
      setIsDeleting(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[550px]">
        <DialogHeader>
          <DialogTitle className="text-center text-lg font-bold">
            {mode === 'edit' ? 'QUẢN LÝ TÀI KHOẢN ĐĂNG NHẬP' : 'TẠO TÀI KHOẢN ĐĂNG NHẬP CHƯƠNG TRÌNH'}
          </DialogTitle>
          <DialogDescription className="text-center text-muted-foreground">
            {isLecturerPreselected 
              ? 'Tạo tài khoản cho giảng viên đã chọn'
              : 'Nhập tên giảng viên để tạo tài khoản'}
          </DialogDescription>
        </DialogHeader>
        
        <div className="grid gap-5 py-4">
          {/* Lecturer name input with autosuggestion */}
          <div className="grid grid-cols-4 items-center gap-4">
            <label htmlFor="lecturer-search" className="text-right text-sm font-medium">
              Họ tên nhân viên
            </label>
            <div className="col-span-3">
              {isLecturerPreselected ? (
                /* Read-only input when lecturer is pre-selected from action column */
                <Input
                  value={searchTerm}
                  readOnly
                  className="bg-muted cursor-not-allowed"
                />
              ) : (
                /* Interactive combobox for creating new accounts */
                <ComboboxInput
                  id="lecturer-search"
                  options={lecturerOptions}
                  value={selectedLecturerId}
                  onValueChange={handleLecturerSelect}
                  inputValue={searchTerm}
                  onInputChange={handleSearchChange}
                  placeholder="Nhập họ tên giảng viên..."
                  loading={isSearching}
                  emptyMessage="Không tìm thấy giảng viên chưa có tài khoản"
                />
              )}
            </div>
          </div>
          
          {/* Staff ID (readonly) */}
          <div className="grid grid-cols-4 items-center gap-4">
            <label htmlFor="userid" className="text-right text-sm font-medium">
              Mã nhân viên
            </label>
            <Input
              id="userid"
              value={formData.userid}
              readOnly
              className="col-span-3 bg-muted cursor-not-allowed"
            />
          </div>
          
          {/* Login name */}
          <div className="grid grid-cols-4 items-center gap-4">
            <label htmlFor="loginname" className="text-right text-sm font-medium">
              Tên đăng nhập
            </label>
            <Input
              id="loginname"
              name="loginname"
              value={formData.loginname}
              onChange={handleInputChange}
              className="col-span-3"
            />
          </div>
          
          {/* Password */}
          <div className="grid grid-cols-4 items-center gap-4">
            <label htmlFor="password" className="text-right text-sm font-medium">
              Mật khẩu
            </label>
            <div className="col-span-3 relative">
              <Input
                id="password"
                name="password"
                type={showPassword ? "text" : "password"}
                value={formData.password}
                onChange={handleInputChange}
                className="pr-10"
              />
              <button
                type="button"
                onClick={togglePasswordVisibility}
                className="absolute inset-y-0 right-0 flex items-center px-3 text-gray-400 hover:text-gray-600"
              >
                {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>
          </div>
          
          {/* Role selection */}
          <div className="grid grid-cols-4 items-center gap-4">
            <label htmlFor="role" className="text-right text-sm font-medium">
              Nhóm quyền
            </label>
            <Select value={formData.role} onValueChange={handleRoleChange}>
              <SelectTrigger className="col-span-3">
                <SelectValue placeholder="Chọn nhóm quyền" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="pgv_role">Phòng Giáo Vụ</SelectItem>
                <SelectItem value="khoa_role">Khoa</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
        
        <DialogFooter className="flex flex-col sm:flex-row gap-2 justify-center">
          <Button
            onClick={handleSubmit}
            disabled={!formData.userid || isSubmitting}
            className="sm:min-w-[130px]"
          >
            {isSubmitting ? (
              <>
                <Loader2 size={16} className="mr-2 animate-spin" />
                Đang xử lý...
              </>
            ) : (
              mode === 'edit' ? "Cập nhật" : "Tạo tài khoản"
            )}
          </Button>
          
          {mode === 'edit' && onDeleteAccount && (
            <Button
              variant="destructive"
              onClick={handleDelete}
              disabled={isDeleting || isSubmitting}
              className="sm:min-w-[130px]"
            >
              {isDeleting ? (
                <>
                  <Loader2 size={16} className="mr-2 animate-spin" />
                  Đang xử lý...
                </>
              ) : (
                "Xóa tài khoản"
              )}
            </Button>
          )}
          
          <Button
            type="button"
            variant="outline"
            onClick={() => onOpenChange(false)}
            className="sm:min-w-[130px]"
          >
            Huỷ
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
} 