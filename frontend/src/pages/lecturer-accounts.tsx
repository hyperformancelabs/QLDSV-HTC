import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { UserCog, Plus, Trash2, Check, X, Loader2, Filter, Ban } from 'lucide-react';
import { useToast } from '@/components/ui/use-toast';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
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
import { LecturerAccountDialog } from '@/components/lecturer-account-dialog';
import { useLecturerAccountsStore } from '@/store/use-lecturer-accounts-store';
import { useAuthStore } from '@/store/use-auth-store';
import { UserRole, LecturerAccount } from '@/types';
import { fetchFaculties, Faculty } from '@/services/facultyService';

export default function LecturerAccountsPage() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const { user } = useAuthStore();
  const {
    accounts,
    loading,
    error,
    selectedFaculty,
    fetchAccounts,
    createAccount,
    deleteAccount,
    toggleAccount,
    setSelectedFaculty,
  } = useLecturerAccountsStore();

  // Local state
  const [searchTerm, setSearchTerm] = useState('');
  const [faculties, setFaculties] = useState<Faculty[]>([]);
  const [facultiesLoading, setFacultiesLoading] = useState(false);
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [selectedLecturer, setSelectedLecturer] = useState<LecturerAccount | null>(null);
  const [accountStatusFilter, setAccountStatusFilter] = useState<string>('all');
  
  // Check if user has permission
  useEffect(() => {
    if (user && user.role !== UserRole.PGV) {
      toast({
        title: "Không có quyền truy cập",
        description: "Bạn không có quyền quản lý tài khoản giảng viên",
        variant: "destructive",
      });
      navigate('/dashboard');
    }
  }, [user, navigate, toast]);

  // Load faculties
  useEffect(() => {
    const loadFaculties = async () => {
      setFacultiesLoading(true);
      try {
        const data = await fetchFaculties();
        setFaculties(data);
      } catch (err) {
        toast({
          title: "Lỗi",
          description: "Không thể tải danh sách khoa",
          variant: "destructive",
        });
      } finally {
        setFacultiesLoading(false);
      }
    };
    
    loadFaculties();
  }, [toast]);

  // Load lecturer accounts
  useEffect(() => {
    fetchAccounts(selectedFaculty || undefined);
  }, [fetchAccounts, selectedFaculty]);

  // Handle faculty filter change
  const handleFacultyChange = (value: string) => {
    setSelectedFaculty(value === 'all' ? null : value);
  };

  // Handle account status filter change
  const handleAccountStatusChange = (value: string) => {
    setAccountStatusFilter(value);
  };

  // Check if lecturer is the current user
  const isCurrentUser = (magv: string): boolean => {
    return user?.magv === magv;
  };

  // Handle create account
  const handleCreateAccount = async (data: {
    loginname: string;
    password: string;
    userid: string;
    role: 'pgv_role' | 'khoa_role';
  }) => {
    try {
      await createAccount(data);
      toast({
        title: "Thành công",
        description: "Đã tạo tài khoản giảng viên thành công",
      });
      return Promise.resolve();
    } catch (err) {
      toast({
        title: "Lỗi",
        description: err instanceof Error ? err.message : "Không thể tạo tài khoản",
        variant: "destructive",
      });
      return Promise.reject(err);
    }
  };

  // Handle delete account
  const handleDeleteAccount = async (magv: string) => {
    // Prevent deleting own account
    if (isCurrentUser(magv)) {
      toast({
        title: "Không được phép",
        description: "Bạn không thể thu hồi tài khoản của chính mình",
        variant: "destructive",
      });
      return Promise.reject(new Error("Không thể thu hồi tài khoản của chính mình"));
    }

    try {
      await deleteAccount(magv);
      toast({
        title: "Thành công",
        description: "Đã thu hồi tài khoản giảng viên thành công",
      });
      return Promise.resolve();
    } catch (err) {
      toast({
        title: "Lỗi",
        description: err instanceof Error ? err.message : "Không thể thu hồi tài khoản",
        variant: "destructive",
      });
      return Promise.reject(err);
    }
  };

  // Handle account toggle (disable/enable)
  const handleToggleAccount = async (magv: string, disable: boolean) => {
    // Prevent disabling own account
    if (disable && isCurrentUser(magv)) {
      toast({
        title: "Không được phép",
        description: "Bạn không thể vô hiệu hoá tài khoản của chính mình",
        variant: "destructive",
      });
      return Promise.reject(new Error("Không thể vô hiệu hoá tài khoản của chính mình"));
    }

    try {
      await toggleAccount(magv, disable);
      toast({
        title: 'Thành công',
        description: disable ? 'Đã vô hiệu hoá tài khoản' : 'Đã kích hoạt lại tài khoản',
      });
      return Promise.resolve();
    } catch (err) {
      toast({
        title: 'Lỗi',
        description: err instanceof Error ? err.message : 'Không thể thay đổi trạng thái tài khoản',
        variant: 'destructive',
      });
      return Promise.reject(err);
    }
  };

  // Filter accounts by search term and account status
  const filteredAccounts = accounts.filter(account => {
    const fullName = `${account.HO} ${account.TEN}`.toLowerCase();
    const searchLower = searchTerm.toLowerCase();
    const matchesSearch = (
      account.MAGV.toLowerCase().includes(searchLower) ||
      fullName.includes(searchLower) ||
      account.TENKHOA.toLowerCase().includes(searchLower)
    );
    
    // Apply account status filter
    if (accountStatusFilter === 'all') {
      return matchesSearch;
    } else if (accountStatusFilter === 'active' && account.HasLogin) {
      return matchesSearch;
    } else if (accountStatusFilter === 'inactive' && !account.HasLogin) {
      return matchesSearch;
    }
    return false;
  });

  return (
    <div className="container mx-auto py-6 space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold flex items-center gap-2">
          <UserCog className="h-8 w-8" />
          Quản lý Giảng viên
        </h1>
        
        <Button 
          className="flex items-center gap-2"
          onClick={() => setCreateDialogOpen(true)}
        >
          <Plus className="h-4 w-4" />
          Tạo tài khoản
        </Button>
      </div>

      {/* Filter and search */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="flex items-center gap-2">
          <Filter className="h-4 w-4 text-muted-foreground" />
          <Select
            value={selectedFaculty || 'all'}
            onValueChange={handleFacultyChange}
            disabled={facultiesLoading}
          >
            <SelectTrigger className="w-[200px]">
              <SelectValue placeholder="Chọn khoa" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Tất cả khoa</SelectItem>
              {faculties.map((faculty) => (
                <SelectItem key={faculty.MAKHOA} value={faculty.MAKHOA}>
                  {faculty.TENKHOA}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <div className="flex items-center gap-2">
          <Filter className="h-4 w-4 text-muted-foreground" />
          <Select
            value={accountStatusFilter}
            onValueChange={handleAccountStatusChange}
          >
            <SelectTrigger className="w-[200px]">
              <SelectValue placeholder="Trạng thái tài khoản" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Tất cả trạng thái</SelectItem>
              <SelectItem value="active">Đã kích hoạt</SelectItem>
              <SelectItem value="inactive">Chưa kích hoạt</SelectItem>
            </SelectContent>
          </Select>
        </div>
        
        <div className="flex-1">
          <Input
            placeholder="Tìm kiếm theo mã GV, họ tên, khoa..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="max-w-md"
          />
        </div>
      </div>

      {/* Error message */}
      {error && (
        <div className="bg-destructive/15 text-destructive p-4 rounded-md">
          {error}
        </div>
      )}

      {/* Lecturer accounts table */}
      <div className="border rounded-lg overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="w-[100px]">Mã GV</TableHead>
              <TableHead>Họ và tên</TableHead>
              <TableHead>Khoa</TableHead>
              <TableHead>Học vị</TableHead>
              <TableHead className="w-[150px]">Trạng thái tài khoản</TableHead>
              <TableHead className="w-[150px]">Vai trò</TableHead>
              <TableHead className="text-right w-[100px]">Thao tác</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={7} className="h-24 text-center">
                  <Loader2 className="h-6 w-6 animate-spin mx-auto" />
                  <p className="mt-2 text-sm text-muted-foreground">
                    Đang tải dữ liệu...
                  </p>
                </TableCell>
              </TableRow>
            ) : filteredAccounts.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} className="h-24 text-center">
                  Không tìm thấy dữ liệu
                </TableCell>
              </TableRow>
            ) : (
              filteredAccounts.map((account) => (
                <TableRow key={account.MAGV}>
                  <TableCell className="font-medium">{account.MAGV}</TableCell>
                  <TableCell>{`${account.HO} ${account.TEN}`}</TableCell>
                  <TableCell>{account.TENKHOA}</TableCell>
                  <TableCell>{account.HOCVI || '—'}</TableCell>
                  <TableCell>
                    {account.HasLogin ? (
                      <span className="inline-flex items-center gap-1 text-green-600 font-medium">
                        <Check className="h-4 w-4" />
                        Đã kích hoạt
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 text-muted-foreground">
                        <X className="h-4 w-4" />
                        Chưa kích hoạt
                      </span>
                    )}
                  </TableCell>
                  <TableCell>{account.RoleName || '—'}</TableCell>
                  <TableCell className="text-right space-x-2">
                    {account.HasLogin ? (
                      <>
                        {/* Toggle disable/enable */}
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleToggleAccount(account.MAGV, true)}
                          className="text-yellow-600 hover:bg-yellow-600/10"
                          title="Vô hiệu hoá tài khoản"
                          disabled={isCurrentUser(account.MAGV)}
                        >
                          <Ban className="h-4 w-4" />
                        </Button>
                        {/* Delete account */}
                        <Button
                          variant="ghost"
                          size="sm"
                          className="text-destructive hover:text-destructive hover:bg-destructive/10"
                          onClick={() => handleDeleteAccount(account.MAGV)}
                          title="Xoá tài khoản"
                          disabled={isCurrentUser(account.MAGV)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </>
                    ) : (
                      // Create account button
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setSelectedLecturer(account);
                          setCreateDialogOpen(true);
                        }}
                        title="Tạo tài khoản"
                      >
                        <Plus className="h-4 w-4" />
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      {/* Account dialog */}
      <LecturerAccountDialog
        open={createDialogOpen}
        onOpenChange={setCreateDialogOpen}
        onCreateAccount={handleCreateAccount}
        onDeleteAccount={handleDeleteAccount}
        selectedLecturer={selectedLecturer}
        mode={selectedLecturer && selectedLecturer.HasLogin ? 'edit' : 'create'}
      />
    </div>
  );
} 