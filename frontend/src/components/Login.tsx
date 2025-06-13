import React, { useState, useEffect, useCallback } from 'react';
import { 
  Card, 
  Tabs, 
  Form, 
  Select, 
  Input, 
  Button, 
  message, 
  Space,
  Typography,
  Avatar,
  Spin
} from 'antd';
import { 
  UserOutlined, 
  TeamOutlined, 
  EyeInvisibleOutlined, 
  EyeTwoTone,
  LoginOutlined,
  LoadingOutlined
} from '@ant-design/icons';
import { GraduationCap } from 'lucide-react';
import authService, { 
  LoginRequest, 
  StudentSearchResult, 
  TeacherSearchResult,
  StudentDetail,
  TeacherDetail 
} from '../services/authService';

const { Title, Text } = Typography;
const { TabPane } = Tabs;
const { Option } = Select;

interface LoginProps {
  onLoginSuccess: (user: any) => void;
}

type UserType = 'student' | 'teacher';

const Login: React.FC<LoginProps> = ({ onLoginSuccess }) => {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [userType, setUserType] = useState<UserType>('student');
  const [searchLoading, setSearchLoading] = useState(false);
  
  // State for dropdowns
  const [studentOptions, setStudentOptions] = useState<StudentSearchResult[]>([]);
  const [teacherOptions, setTeacherOptions] = useState<TeacherSearchResult[]>([]);
  
  // Debounced search
  const [searchTimeout, setSearchTimeout] = useState<NodeJS.Timeout | null>(null);

  // Validation state
  const [validationErrors, setValidationErrors] = useState<{
    userName?: string;
    userCode?: string;
  }>({});

  // Generate random field names to prevent browser detection
  const [randomFieldNames] = useState({
    username: `field_${Math.random().toString(36).substr(2, 9)}`,
    usercode: `field_${Math.random().toString(36).substr(2, 9)}`,
    password: `field_${Math.random().toString(36).substr(2, 9)}`
  });

  // Load initial data when tab changes
  useEffect(() => {
    loadInitialData();
    // Clear validation errors when switching tabs
    setValidationErrors({});
    form.resetFields();
  }, [userType]);

  // Disable password managers completely
  useEffect(() => {
    // Add meta tag to disable autofill
    const meta = document.createElement('meta');
    meta.name = 'format-detection';
    meta.content = 'telephone=no, email=no';
    document.head.appendChild(meta);

    // Add script to disable password saving
    const script = document.createElement('script');
    script.textContent = `
      // Disable password saving
      window.addEventListener('beforeunload', function() {
        const forms = document.querySelectorAll('form');
        forms.forEach(form => {
          const inputs = form.querySelectorAll('input[type="password"]');
          inputs.forEach(input => input.value = '');
        });
      });
    `;
    document.head.appendChild(script);

    return () => {
      document.head.removeChild(meta);
      document.head.removeChild(script);
    };
  }, []);

  const loadInitialData = async () => {
    try {
      if (userType === 'student') {
        const students = await authService.getAllStudents();
        setStudentOptions(students);
      } else {
        const teachers = await authService.getAllTeachers();
        setTeacherOptions(teachers);
      }
    } catch (error) {
      console.error('Error loading initial data:', error);
    }
  };

  // Validate user by name when blur occurs
  const validateUserByName = async () => {
    const selectedName = form.getFieldValue('userName');
    const selectedCode = form.getFieldValue('userCode');
    
    // If both name and code are filled, skip validation (they're synced)
    if (selectedName && selectedCode) {
      setValidationErrors(prev => ({ ...prev, userName: undefined }));
      return;
    }
    
    // If only name is filled, try to find matching user
    if (!selectedName) return;

    try {
      // Check if the name exists in current options
      if (userType === 'student') {
        const matchedStudent = studentOptions.find(s => 
          `${s.ho} ${s.ten}` === selectedName || 
          s.display_name === selectedName
        );
        
        if (matchedStudent) {
          form.setFieldsValue({ userCode: matchedStudent.masv });
          setValidationErrors(prev => ({ ...prev, userName: undefined }));
        } else {
          setValidationErrors(prev => ({ ...prev, userName: 'Sinh viên không tồn tại' }));
        }
      } else {
        const matchedTeacher = teacherOptions.find(t => 
          `${t.ho} ${t.ten}` === selectedName || 
          t.display_name === selectedName
        );
        
        if (matchedTeacher) {
          form.setFieldsValue({ userCode: matchedTeacher.magv });
          setValidationErrors(prev => ({ ...prev, userName: undefined }));
        } else {
          setValidationErrors(prev => ({ ...prev, userName: 'Giảng viên không tồn tại' }));
        }
      }
    } catch (error) {
      const errorMsg = userType === 'student' ? 'Sinh viên không tồn tại' : 'Giảng viên không tồn tại';
      setValidationErrors(prev => ({ ...prev, userName: errorMsg }));
    }
  };

  // Validate user by code when blur occurs
  const validateUserByCode = async (code: string) => {
    if (!code || code.length < 3) {
      form.setFieldsValue({ userName: undefined });
      setValidationErrors(prev => ({ ...prev, userCode: undefined }));
      return;
    }

    try {
      if (userType === 'student') {
        const student = await authService.getStudentById(code);
        form.setFieldsValue({ 
          userName: `${student.ho} ${student.ten}`
        });
        setValidationErrors(prev => ({ ...prev, userCode: undefined }));
        
        // Update the select options to include this student if not already present
        const exists = studentOptions.find(s => s.masv === code);
        if (!exists) {
          const newOption: StudentSearchResult = {
            masv: student.masv,
            ho: student.ho,
            ten: student.ten,
            display_name: `${student.ho} ${student.ten}`
          };
          setStudentOptions(prev => [newOption, ...prev]);
        }
      } else {
        const teacher = await authService.getTeacherById(code);
        form.setFieldsValue({ 
          userName: `${teacher.ho} ${teacher.ten}`
        });
        setValidationErrors(prev => ({ ...prev, userCode: undefined }));
        
        // Update the select options to include this teacher if not already present
        const exists = teacherOptions.find(t => t.magv === code);
        if (!exists) {
          const newOption: TeacherSearchResult = {
            magv: teacher.magv,
            ho: teacher.ho,
            ten: teacher.ten,
            display_name: `${teacher.ho} ${teacher.ten}`
          };
          setTeacherOptions(prev => [newOption, ...prev]);
        }
      }
    } catch (error) {
      const errorMsg = userType === 'student' ? 'Mã sinh viên không tồn tại' : 'Mã giảng viên không tồn tại';
      setValidationErrors(prev => ({ ...prev, userCode: errorMsg }));
      form.setFieldsValue({ userName: undefined });
    }
  };

  // Debounced search function
  const debouncedSearch = useCallback((searchTerm: string) => {
    if (searchTimeout) {
      clearTimeout(searchTimeout);
    }

    const timeout = setTimeout(async () => {
      if (searchTerm.length >= 1) {
        setSearchLoading(true);
        try {
          if (userType === 'student') {
            const results = await authService.searchStudents(searchTerm);
            setStudentOptions(results);
          } else {
            const results = await authService.searchTeachers(searchTerm);
            setTeacherOptions(results);
          }
        } catch (error) {
          console.error('Search error:', error);
        } finally {
          setSearchLoading(false);
        }
      } else {
        // If search term is empty, load all data
        loadInitialData();
      }
    }, 300); // 300ms debounce

    setSearchTimeout(timeout);
  }, [userType, searchTimeout]);

  // Handle name selection
  const handleNameSelect = async (selectedId: string) => {
    try {
      if (userType === 'student') {
        const student = await authService.getStudentById(selectedId);
        form.setFieldsValue({ 
          userCode: student.masv,
          userName: `${student.ho} ${student.ten}`
        });
        setValidationErrors(prev => ({ ...prev, userName: undefined }));
      } else {
        const teacher = await authService.getTeacherById(selectedId);
        form.setFieldsValue({ 
          userCode: teacher.magv,
          userName: `${teacher.ho} ${teacher.ten}`
        });
        setValidationErrors(prev => ({ ...prev, userName: undefined }));
      }
    } catch (error) {
      message.error('Không thể tải thông tin người dùng');
    }
  };

  // Handle code input with real-time sync (but validation only on blur)
  const handleCodeChange = (code: string) => {
    // Clear validation error when user starts typing
    if (validationErrors.userCode) {
      setValidationErrors(prev => ({ ...prev, userCode: undefined }));
    }
    
    // Only clear name field if code becomes too short, don't validate yet
    if (!code || code.length < 3) {
      form.setFieldsValue({ userName: undefined });
    }
  };

  // Handle form submission
  const handleSubmit = async (values: any) => {
    // Check for validation errors before submitting
    if (validationErrors.userName || validationErrors.userCode) {
      message.error('Vui lòng sửa các lỗi trước khi đăng nhập');
      return;
    }

    setLoading(true);
    try {
      const loginData: LoginRequest = {
        id: values.userCode,
        password: values.password,
        user_type: userType
      };

      const response = await authService.login(loginData);
      
      message.success(`Đăng nhập thành công! Chào mừng ${response.user.ho} ${response.user.ten}`);
      onLoginSuccess(response.user);
    } catch (error: any) {
      message.error(error.message || 'Đăng nhập thất bại');
    } finally {
      setLoading(false);
    }
  };

  // Handle tab change
  const handleTabChange = (activeKey: string) => {
    setUserType(activeKey as UserType);
    form.resetFields();
    setValidationErrors({});
  };

  // Filter and sort options for dropdown
  const getSelectOptions = () => {
    if (userType === 'student') {
      // Group by name and add numbering for duplicates
      const nameGroups: { [key: string]: StudentSearchResult[] } = {};
      
      studentOptions.forEach(student => {
        const fullName = `${student.ho} ${student.ten}`;
        if (!nameGroups[fullName]) {
          nameGroups[fullName] = [];
        }
        nameGroups[fullName].push(student);
      });

      // Sort and add numbering
      const optionsWithNumbers: (StudentSearchResult & { displayName: string })[] = [];
      
      Object.keys(nameGroups).sort().forEach(name => {
        const group = nameGroups[name];
        // Sort by MASV within group
        group.sort((a, b) => a.masv.localeCompare(b.masv));
        
        if (group.length === 1) {
          optionsWithNumbers.push({
            ...group[0],
            displayName: name
          });
        } else {
          group.forEach((student, index) => {
            optionsWithNumbers.push({
              ...student,
              displayName: `${name} ${index + 1}`
            });
          });
        }
      });

      return optionsWithNumbers.map(student => (
        <Option key={student.masv} value={student.masv}>
          {student.displayName}
        </Option>
      ));
    } else {
      // Same logic for teachers
      const nameGroups: { [key: string]: TeacherSearchResult[] } = {};
      
      teacherOptions.forEach(teacher => {
        const fullName = `${teacher.ho} ${teacher.ten}`;
        if (!nameGroups[fullName]) {
          nameGroups[fullName] = [];
        }
        nameGroups[fullName].push(teacher);
      });

      const optionsWithNumbers: (TeacherSearchResult & { displayName: string })[] = [];
      
      Object.keys(nameGroups).sort().forEach(name => {
        const group = nameGroups[name];
        // Sort by MAGV within group
        group.sort((a, b) => a.magv.localeCompare(b.magv));
        
        if (group.length === 1) {
          optionsWithNumbers.push({
            ...group[0],
            displayName: name
          });
        } else {
          group.forEach((teacher, index) => {
            optionsWithNumbers.push({
              ...teacher,
              displayName: `${name} ${index + 1}`
            });
          });
        }
      });

      return optionsWithNumbers.map(teacher => (
        <Option key={teacher.magv} value={teacher.magv}>
          {teacher.displayName}
        </Option>
      ));
    }
  };

  return (
    <div 
      className="login-container"
      data-lpignore="true"
      data-1p-ignore="true" 
      data-bwignore="true"
      data-form-type="other"
    >
      {/* Hidden honeypot form to confuse password managers */}
      <form 
        style={{ 
          position: 'absolute', 
          left: '-9999px', 
          opacity: 0, 
          pointerEvents: 'none',
          height: 0,
          overflow: 'hidden'
        }}
        autoComplete="off"
        data-lpignore="true"
      >
        <input type="text" name="username" autoComplete="username" tabIndex={-1} />
        <input type="password" name="password" autoComplete="current-password" tabIndex={-1} />
        <input type="email" name="email" autoComplete="email" tabIndex={-1} />
        <input type="submit" value="Login" tabIndex={-1} />
      </form>

      <div style={{ width: '100%', maxWidth: '480px' }}>
        {/* Logo and Title */}
        <div style={{ textAlign: 'center', marginBottom: '32px' }}>
          <Avatar 
            size={80} 
            style={{ 
              backgroundColor: '#1890ff', 
              marginBottom: '16px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}
          >
            <GraduationCap size={40} color="white" />
          </Avatar>
          <Title level={2} style={{ color: 'white', marginBottom: '8px' }}>
            HỆ THỐNG QUẢN LÝ ĐIỂM SINH VIÊN
          </Title>
          <Text style={{ color: 'rgba(255, 255, 255, 0.8)', fontSize: '18px', fontWeight: 500 }}>
            HỆ TÍN CHỈ
          </Text>
        </div>

        <Card 
          style={{ 
            borderRadius: '12px',
            boxShadow: '0 20px 40px rgba(0, 0, 0, 0.1)',
            border: 'none'
          }}
        >
          <div style={{ textAlign: 'center', marginBottom: '24px' }}>
            <Title level={3} style={{ marginBottom: '8px' }}>
              Đăng nhập hệ thống
            </Title>
            <Text type="secondary">
              Vui lòng nhập thông tin để truy cập hệ thống
            </Text>
          </div>

          <Tabs 
            activeKey={userType}
            onChange={handleTabChange}
            centered
            size="large"
          >
            <TabPane 
              tab={
                <Space>
                  <UserOutlined />
                  <span>SINH VIÊN</span>
                </Space>
              } 
              key="student"
            >
              <Form
                form={form}
                layout="vertical"
                onFinish={handleSubmit}
                autoComplete="off"
                size="large"
              >
                <Form.Item
                  label="Họ tên"
                  name="userName"
                  rules={[{ required: true, message: 'Vui lòng chọn họ tên!' }]}
                  validateStatus={validationErrors.userName ? 'error' : ''}
                  help={validationErrors.userName}
                >
                  <Select
                    showSearch
                    filterOption={false}
                    onSearch={debouncedSearch}
                    onSelect={handleNameSelect}
                    onBlur={() => validateUserByName()}
                    notFoundContent={searchLoading ? <Spin size="small" /> : 'Không tìm thấy'}
                    loading={searchLoading}
                    autoComplete="off"
                    getPopupContainer={trigger => trigger.parentElement || document.body}
                  >
                    {getSelectOptions()}
                  </Select>
                </Form.Item>

                <Form.Item
                  label="Mã sinh viên"
                  name="userCode"
                  rules={[{ required: true, message: 'Vui lòng nhập mã sinh viên!' }]}
                  validateStatus={validationErrors.userCode ? 'error' : ''}
                  help={validationErrors.userCode}
                >
                  <Input 
                    onChange={(e) => handleCodeChange(e.target.value)}
                    onBlur={(e) => validateUserByCode(e.target.value)}
                    autoComplete="one-time-code"
                    autoCapitalize="off"
                    autoCorrect="off"
                    spellCheck={false}
                    data-form-type="other"
                    name={randomFieldNames.usercode}
                    data-lpignore="true"
                    data-1p-ignore="true"
                    data-bwignore="true"
                  />
                </Form.Item>

                <Form.Item
                  label="Mật khẩu"
                  name="password"
                  rules={[{ required: true, message: 'Vui lòng nhập mật khẩu!' }]}
                >
                  <Input.Password 
                    iconRender={(visible) => (visible ? <EyeTwoTone /> : <EyeInvisibleOutlined />)}
                    autoComplete="one-time-code"
                    autoCapitalize="off"
                    autoCorrect="off"
                    spellCheck={false}
                    data-form-type="other"
                    name={randomFieldNames.password}
                    data-lpignore="true"
                    data-1p-ignore="true"
                    data-bwignore="true"
                  />
                </Form.Item>

                <Form.Item style={{ marginBottom: 0 }}>
                  <Button 
                    type="primary" 
                    htmlType="submit" 
                    block 
                    size="large"
                    loading={loading}
                    style={{ 
                      height: '48px',
                      borderRadius: '8px',
                      fontSize: '16px',
                      fontWeight: 500
                    }}
                  >
                    {loading ? (
                      <Space>
                        <LoadingOutlined />
                        Đang đăng nhập...
                      </Space>
                    ) : (
                      <Space>
                        <LoginOutlined />
                        Đăng nhập
                      </Space>
                    )}
                  </Button>
                </Form.Item>
              </Form>
            </TabPane>

            <TabPane 
              tab={
                <Space>
                  <TeamOutlined />
                  <span>GIẢNG VIÊN</span>
                </Space>
              } 
              key="teacher"
            >
              <Form
                form={form}
                layout="vertical"
                onFinish={handleSubmit}
                autoComplete="off"
                size="large"
              >
                <Form.Item
                  label="Họ tên"
                  name="userName"
                  rules={[{ required: true, message: 'Vui lòng chọn họ tên!' }]}
                  validateStatus={validationErrors.userName ? 'error' : ''}
                  help={validationErrors.userName}
                >
                  <Select
                    showSearch
                    filterOption={false}
                    onSearch={debouncedSearch}
                    onSelect={handleNameSelect}
                    onBlur={() => validateUserByName()}
                    notFoundContent={searchLoading ? <Spin size="small" /> : 'Không tìm thấy'}
                    loading={searchLoading}
                    autoComplete="off"
                    getPopupContainer={trigger => trigger.parentElement || document.body}
                  >
                    {getSelectOptions()}
                  </Select>
                </Form.Item>

                <Form.Item
                  label="Mã giảng viên"
                  name="userCode"
                  rules={[{ required: true, message: 'Vui lòng nhập mã giảng viên!' }]}
                  validateStatus={validationErrors.userCode ? 'error' : ''}
                  help={validationErrors.userCode}
                >
                  <Input 
                    onChange={(e) => handleCodeChange(e.target.value)}
                    onBlur={(e) => validateUserByCode(e.target.value)}
                    autoComplete="one-time-code"
                    autoCapitalize="off"
                    autoCorrect="off"
                    spellCheck={false}
                    data-form-type="other"
                    name={randomFieldNames.usercode}
                    data-lpignore="true"
                    data-1p-ignore="true"
                    data-bwignore="true"
                  />
                </Form.Item>

                <Form.Item
                  label="Mật khẩu"
                  name="password"
                  rules={[{ required: true, message: 'Vui lòng nhập mật khẩu!' }]}
                >
                  <Input.Password 
                    iconRender={(visible) => (visible ? <EyeTwoTone /> : <EyeInvisibleOutlined />)}
                    autoComplete="one-time-code"
                    autoCapitalize="off"
                    autoCorrect="off"
                    spellCheck={false}
                    data-form-type="other"
                    name={randomFieldNames.password}
                    data-lpignore="true"
                    data-1p-ignore="true"
                    data-bwignore="true"
                  />
                </Form.Item>

                <Form.Item style={{ marginBottom: 0 }}>
                  <Button 
                    type="primary" 
                    htmlType="submit" 
                    block 
                    size="large"
                    loading={loading}
                    style={{ 
                      height: '48px',
                      borderRadius: '8px',
                      fontSize: '16px',
                      fontWeight: 500
                    }}
                  >
                    {loading ? (
                      <Space>
                        <LoadingOutlined />
                        Đang đăng nhập...
                      </Space>
                    ) : (
                      <Space>
                        <LoginOutlined />
                        Đăng nhập
                      </Space>
                    )}
                  </Button>
                </Form.Item>
              </Form>
            </TabPane>
          </Tabs>

          {/* Demo credentials */}
          <div style={{ 
            marginTop: '24px', 
            padding: '16px', 
            backgroundColor: '#f5f5f5', 
            borderRadius: '8px' 
          }}>
            <Text strong style={{ fontSize: '14px', color: '#666' }}>
              Tài khoản demo:
            </Text>
            <div style={{ marginTop: '8px', fontSize: '13px', color: '#888' }}>
              <div><strong>PGV:</strong> pgv_user / PGV@123456</div>
              <div><strong>Khoa:</strong> khoa_user / KHOA@123456</div>
              <div><strong>GV (PGV Role):</strong> GV045 / GV045pass123# (SQL Server auth)</div>
              <div><strong>SV:</strong> N21DCCN064 / 123456</div>
            </div>
            <div style={{ marginTop: '8px', fontSize: '12px', color: '#999' }}>
              <em>Note: Teacher logins require SQL Server authentication. On macOS with ODBC timeout issues, teacher login may fail even with correct credentials.</em>
            </div>
          </div>
        </Card>

        <div style={{ 
          textAlign: 'center', 
          marginTop: '24px',
          color: 'rgba(255, 255, 255, 0.7)',
          fontSize: '14px'
        }}>
          <Space split={<span>•</span>}>
            <span>📞 Liên hệ hỗ trợ</span>
            <span>📖 Hướng dẫn sử dụng</span>
          </Space>
        </div>
      </div>
    </div>
  );
};

export default Login; 