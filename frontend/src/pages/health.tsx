import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { CheckCircle2, XCircle, AlertTriangle, RefreshCw, Server, Database, Clock } from 'lucide-react';
import { HealthCheckResponse } from '@/types';
import { toast } from '@/components/ui/use-toast';

export default function HealthPage() {
  const [healthData, setHealthData] = useState<HealthCheckResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchHealthData = async () => {
    setLoading(true);
    setError(null);
    
    try {
      // In a real app, we would fetch from the API
      // const response = await fetch('/api/v1/health');
      // const data = await response.json();
      
      // For demo purposes, we'll simulate the API response
      await new Promise(resolve => setTimeout(resolve, 800));
      
      // Simulate different health statuses randomly
      const statuses = ['healthy', 'warning', 'unhealthy'];
      const randomStatus = statuses[Math.floor(Math.random() * 3)] as 'healthy' | 'warning' | 'unhealthy';
      
      const mockData: HealthCheckResponse = {
        status: randomStatus,
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        services: {
          api: {
            status: randomStatus === 'unhealthy' ? 'down' : 'up',
            responseTime: Math.floor(Math.random() * 500),
          },
          database: {
            status: randomStatus === 'unhealthy' ? 'down' : randomStatus === 'warning' ? Math.random() > 0.5 ? 'down' : 'up' : 'up',
            version: '16.0.1',
            error: randomStatus === 'unhealthy' ? 'Connection timeout' : undefined,
          },
        },
      };
      
      setHealthData(mockData);
      
      if (randomStatus === 'unhealthy') {
        toast({
          variant: 'destructive',
          title: 'Hệ thống đang gặp sự cố',
          description: 'Vui lòng liên hệ quản trị viên để được hỗ trợ.',
        });
      } else if (randomStatus === 'warning') {
        toast({
          variant: 'default',
          title: 'Cảnh báo',
          description: 'Hệ thống đang hoạt động nhưng có một số vấn đề.',
        });
      }
    } catch (err) {
      setError('Không thể kết nối đến máy chủ. Vui lòng thử lại sau.');
      toast({
        variant: 'destructive',
        title: 'Lỗi kết nối',
        description: 'Không thể kết nối đến máy chủ. Vui lòng thử lại sau.',
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHealthData();
  }, []);

  const getStatusIcon = (status: 'healthy' | 'warning' | 'unhealthy') => {
    switch (status) {
      case 'healthy':
        return <CheckCircle2 className="h-8 w-8 text-green-500" />;
      case 'warning':
        return <AlertTriangle className="h-8 w-8 text-amber-500" />;
      case 'unhealthy':
        return <XCircle className="h-8 w-8 text-red-500" />;
      default:
        return null;
    }
  };

  const getStatusText = (status: 'healthy' | 'warning' | 'unhealthy') => {
    switch (status) {
      case 'healthy':
        return 'Hệ thống hoạt động bình thường';
      case 'warning':
        return 'Hệ thống đang hoạt động nhưng có một số vấn đề';
      case 'unhealthy':
        return 'Hệ thống đang gặp sự cố';
      default:
        return 'Không xác định';
    }
  };

  const getStatusClass = (status: 'healthy' | 'warning' | 'unhealthy') => {
    switch (status) {
      case 'healthy':
        return 'bg-green-50 border-green-200 text-green-700';
      case 'warning':
        return 'bg-amber-50 border-amber-200 text-amber-700';
      case 'unhealthy':
        return 'bg-red-50 border-red-200 text-red-700';
      default:
        return 'bg-gray-50 border-gray-200 text-gray-700';
    }
  };

  const getServiceStatusIcon = (status: 'up' | 'down') => {
    return status === 'up' ? (
      <CheckCircle2 className="h-5 w-5 text-green-500" />
    ) : (
      <XCircle className="h-5 w-5 text-red-500" />
    );
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('vi-VN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    }).format(date);
  };

  return (
    <div className="container mx-auto py-8 px-4">
      <div className="flex flex-col items-center justify-center mb-8">
        <h1 className="text-3xl font-bold mb-2">Trạng thái hệ thống</h1>
        <p className="text-muted-foreground">
          Kiểm tra trạng thái hoạt động của hệ thống QLDSV-HTC
        </p>
      </div>

      {loading ? (
        <div className="flex flex-col items-center justify-center py-12">
          <RefreshCw className="h-12 w-12 text-primary animate-spin mb-4" />
          <p className="text-lg">Đang kiểm tra trạng thái hệ thống...</p>
        </div>
      ) : error ? (
        <Card className="border-red-200 bg-red-50">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-red-700">
              <XCircle className="h-6 w-6" />
              Lỗi kết nối
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-red-700">{error}</p>
          </CardContent>
          <CardFooter>
            <Button onClick={fetchHealthData} className="flex items-center gap-2">
              <RefreshCw className="h-4 w-4" />
              Thử lại
            </Button>
          </CardFooter>
        </Card>
      ) : healthData ? (
        <div className="space-y-6">
          {/* Overall Status */}
          <Card className={`border-2 ${getStatusClass(healthData.status)}`}>
            <CardHeader className="pb-2">
              <CardTitle className="flex items-center gap-3">
                {getStatusIcon(healthData.status)}
                <span>{getStatusText(healthData.status)}</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex flex-col gap-1">
                <div className="flex items-center gap-2 text-sm">
                  <Clock className="h-4 w-4 text-muted-foreground" />
                  <span className="text-muted-foreground">
                    Cập nhật lần cuối: {formatDate(healthData.timestamp)}
                  </span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="text-muted-foreground">
                    Phiên bản: {healthData.version}
                  </span>
                </div>
              </div>
            </CardContent>
            <CardFooter>
              <Button onClick={fetchHealthData} variant="outline" className="flex items-center gap-2">
                <RefreshCw className="h-4 w-4" />
                Kiểm tra lại
              </Button>
            </CardFooter>
          </Card>

          {/* Services Status */}
          <div className="grid gap-4 md:grid-cols-2">
            {/* API Service */}
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Server className="h-5 w-5 text-primary" />
                  API Service
                </CardTitle>
                <CardDescription>
                  Dịch vụ API RESTful
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex items-center justify-between">
                  <span>Trạng thái:</span>
                  <div className="flex items-center gap-2">
                    {getServiceStatusIcon(healthData.services.api.status)}
                    <span>{healthData.services.api.status === 'up' ? 'Hoạt động' : 'Không hoạt động'}</span>
                  </div>
                </div>
                <div className="flex items-center justify-between mt-2">
                  <span>Thời gian phản hồi:</span>
                  <span className={healthData.services.api.responseTime > 300 ? 'text-amber-500' : 'text-green-500'}>
                    {healthData.services.api.responseTime} ms
                  </span>
                </div>
              </CardContent>
            </Card>

            {/* Database Service */}
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Database className="h-5 w-5 text-primary" />
                  Database Service
                </CardTitle>
                <CardDescription>
                  SQL Server Database
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex items-center justify-between">
                  <span>Trạng thái:</span>
                  <div className="flex items-center gap-2">
                    {getServiceStatusIcon(healthData.services.database.status)}
                    <span>{healthData.services.database.status === 'up' ? 'Hoạt động' : 'Không hoạt động'}</span>
                  </div>
                </div>
                <div className="flex items-center justify-between mt-2">
                  <span>Phiên bản:</span>
                  <span>{healthData.services.database.version || 'N/A'}</span>
                </div>
                {healthData.services.database.error && (
                  <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-md text-red-700 text-sm">
                    <div className="font-medium">Lỗi:</div>
                    <div>{healthData.services.database.error}</div>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>

          {/* Troubleshooting */}
          {(healthData.status === 'warning' || healthData.status === 'unhealthy') && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <AlertTriangle className="h-5 w-5 text-amber-500" />
                  Khắc phục sự cố
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <h4 className="font-medium mb-1">Các bước khắc phục:</h4>
                  <ul className="list-disc pl-5 space-y-1">
                    <li>Kiểm tra kết nối mạng của bạn</li>
                    <li>Làm mới trang và thử lại</li>
                    <li>Xóa cache trình duyệt và thử lại</li>
                    <li>Liên hệ quản trị viên nếu vấn đề vẫn tiếp diễn</li>
                  </ul>
                </div>
                <div>
                  <h4 className="font-medium mb-1">Thông tin liên hệ hỗ trợ:</h4>
                  <p>Email: support@qldsv-htc.edu.vn</p>
                  <p>Điện thoại: (028) 1234-5678</p>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      ) : null}
    </div>
  );
} 