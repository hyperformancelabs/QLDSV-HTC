# TẠO PROJECT

## 1. Tạo Project:
Khởi động MS Visual Studio, Chọn **File / New / Project**

Trong Template Gallery, chọn **Ribbon Based Application** để tạo Project QLVT theo Template Ribbon đã thiết kế sẵn trong DevExpress.

Chọn **Create Project**, DevExpress sẽ tạo ra 1 project dựa vào template Ribbon đã thiết kế sẵn.

Lúc này, ta sẽ thấy `Form1` sẽ xuất hiện, ta chọn Font chữ cho Form: **Times New Roman, size 11**, và đặt tên cho form là `frmMain.vb`. Đây chính là Form sẽ chạy chính thức khi ta kích hoạt Project.
Trên Form này, ta thấy xuất hiện sẵn thanh Ribbon để ta thiết kế menu theo dạng Ribbon.

**Lưu ý**: Về sau này, nếu ta muốn thêm 1 form mới vào Project thì: Right click trên tên Project / **Add / Windows Form**.

## 2. Thiết kế Ribbon menu:

*   **Button**: thêm 1 button mới vào Page, right click trên Button, chọn **Add Button**.
*   **Page**: thêm 1 page mới vào ribbon, right click trên Page, chọn **Add page**.

Ta nên đặt tên cho các button trên `RibbonControl`: vào trang **Properties**, gõ tên button ở thuộc tính `Name`, hoặc Right click trên `RibbonControl`, chọn **Run Designer**:

Trên `frmMain`:
*   Chọn **Navigation & Layout** trong Toolbox, kéo `XtraTabbedMdiManager` vào form để khi ta chọn mở các form thì các Form sẽ xuất hiện có dạng như các Tab trên `frmMain`.
*   Cho thuộc tính `WindowState`: **Maximized**.
*   Vào **ViewCode**, ta nhập Hàm `CheckExists`:

```vbnet
Private Function CheckExists(ByVal ftype As Type) As Form
    CheckExists = Me
    Dim f As Form
    For Each f In Me.MdiChildren
        If (f.GetType() = ftype) Then
            CheckExists = f
            Exit Function
        End If
    Next
End Function
```
Hàm `CheckExists` dùng để kiểm tra 1 form nào đó đã load vào bộ nhớ chưa, nếu chưa có trong bộ nhớ thì hàm sẽ trả về `Me` (là form `frmMain`), còn nếu form đó đã mở rồi thì Hàm sẽ trả về chính đối tượng form đó trong bộ nhớ.
________________

Trong C#, hàm `CheckExists` được viết như sau:
```csharp
private Form CheckExists(Type ftype)
{
    foreach (Form f in this.MdiChildren)
        if (f.GetType() == ftype)
            return f;
    return null;
}
```

Cách sử dụng hàm `CheckExists`: Khi user click vào nút lệnh trên menu để mở form, ví dụ như form `frmNhanvien`, thì ta sẽ cài đặt đoạn code sau:

```vbnet
Private Sub btnNhanvien_ItemClick(ByVal sender As System.Object, ByVal e As DevExpress.XtraBars.ItemClickEventArgs) Handles btnNhanvien.ItemClick
    Dim frm As Object
    frm = CheckExists(frmNhanvien.GetType())
    If (frm.GetType() <> Me.GetType()) Then  ' form đã được mở
        frm.Activate()                       ' nên ta cho active lại
    Else                                     ' frmNhanvien chưa mở
        frm = New frmNhanvien                ' tạo đối tượng frmNhanvien trong bộ nhớ
        frm.MdiParent = Me                   ' cho frmMain là form cha
        frm.Show()
    End If
End Sub
```

Trong C#:
```csharp
private void btnNhanvien_ItemClick(object sender, DevExpress.XtraBars.ItemClickEventArgs e)
{
    Form frm = this.CheckExists(typeof(frmNhanvien));
    if (frm != null) frm.Activate();
    else
    {
        frmNhanvien f = new frmNhanvien();
        f.MdiParent = this;
        f.Show();
    }
}
```

## 3. Tạo Simple form :
Form dạng này sẽ cho ta cập nhật dữ liệu trên 1 table. Giả sử ta tạo form `frmNhanvien` để cho phép user cập nhật danh sách nhân viên trong cơ sở dữ liệu. Các bước thực hiện:

### a. Tạo DataSet trong Project:
DataSet là 1 đối tượng, trong đó sẽ chứa các `DataTable`. Mỗi `DataTable` chứa dữ liệu trong 1 Table của cơ sở dữ liệu, hoặc kết quả trả về từ 1 View, Stored Procedure trong SQL Server, Select-Statement.
Ví dụ. Ta tạo DataSet tên `DS` chứa các `DataTable` là các table trong cơ sở dữ liệu QLVT.
Trên menu, chọn **Data/Add New Data Source**:

Lúc này trong cửa sổ Solution Explorer, sẽ có thêm `DS.xsd`. Double Click trên `DS.xsd`, ta sẽ thấy các `DataTable`:

Ta hiệu chỉnh các liên kết giữa các Data Table trong DataSet: Right click trên các mối liên kết, chọn **Edit Relation**:

Ta thực hiện điều này trên tất cả các mối liên kết; điều này sẽ giúp ta:
*   Thực hiện việc kiểm tra việc xóa dữ liệu trên đầu khóa chính thì nếu dữ liệu đó đã có trong khóa ngoại thì sẽ không cho xóa;
*   Hỗ trợ khi ta chọn 1 mẫu tin (nhân viên) trên đầu khóa chính, thì các mẫu tin trên đầu khóa ngoại (Phát sinh) sẽ tự động chỉ hiển thị các thông tin có liên quan đến khóa chính đó (chỉ hiển thị các phiếu do nhân viên đó đã lập).
*   Sau khi tạo xong DataSet, trong Project sẽ có thêm file `app.config`, file này sẽ chứa 1 chuỗi kết nối tới Database trên SQL Server. Về sau này, nếu ta cài đặt Database trên Server khác thì chỉ cần hiệu chỉnh chuỗi kết nối trong file `app.config`.

```xml
<?xml version="1.0"?>
<configuration>
    <configSections>
    </configSections>
    <connectionStrings>
        <add name="QLVT.Settings.QLVT_D14QT02ConnectionString" connectionString="Data Source=THU-PC;Initial Catalog=QL_VATTU;User ID=sa;Password=kc"
            providerName="System.Data.SqlClient" />
    </connectionStrings>
    <system.diagnostics>
        <sources>
            <!-- This section defines the logging configuration for My.Application.Log -->
            <source name="DefaultSource" switchName="DefaultSwitch">
                <listeners>
                    <add name="FileLog"/>
                    <!-- Uncomment the below section to write to the Application Event Log -->
                    <!--<add name="EventLog"/>-->
                </listeners>
            </source>
        </sources>
        <switches>
            <add name="DefaultSwitch" value="Information"/>
        </switches>
        <sharedListeners>
            <add name="FileLog" type="Microsoft.VisualBasic.Logging.FileLogTraceListener, Microsoft.VisualBasic, Version=8.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a, processorArchitecture=MSIL" initializeData="FileLogWriter"/>
            <!-- Uncomment the below section and replace APPLICATION_NAME with the name of your application to write to the Application Event Log -->
            <!--<add name="EventLog" type="System.Diagnostics.EventLogTraceListener" initializeData="APPLICATION_NAME"/> -->
        </sharedListeners>
    </system.diagnostics>
<startup useLegacyV2RuntimeActivationPolicy="true"><supportedRuntime version="v4.0" sku=".NETFramework,Version=v4.0"/></startup></configuration>
```

### b. Tạo Form `frmNhanvien`:
Add 1 form mới tên `frmNhanvien` vào Project, thiết lập Font: **Times New Roman, Size 11**, Window State: **Maximized**.

#### b1. Thiết kế form
-   Tạo menu lệnh cho `frmNhanvien`: Kéo `BarManager` trong **Navigation & Layout** vào `frmNhanvien`, sau đó Add các Button lệnh vào (`btnThem`, `btnSua`, `btnGhi`, `btnXoa`, `btnPhuchoi`, `btnRefresh`, `btnInDSNV`, `btnThoat`) (xem hình). Trên mỗi nút lệnh, ta chọn đánh dấu **Image and Text**.

    Ta chọn icon hình cùng hiển thị với Text trong button: chọn hình trong **Glyph**.

-   Kéo DataTable `Nhanvien` trong cửa sổ Data Source vào `frmNhanvien`, ta sẽ có thêm các đối tượng sau: `NhanvienGridControl` (đổi tên là `gcNV`), `NHANVIENBindingSource` (đổi tên `bdsNV`), `NHANVIENTableAdapter`. Ta xóa `NHANVIENBindingNavigator`.
-   Ta thiết lập: `gcNV.Dock = Top` để `GridControl` lúc nào cũng nằm ở phần trên của Form.

Lúc này, phần mềm sẽ tự động thêm vào phần Code của form `frmNhanvien` các chương trình con sau:
```vbnet
Public Class frmNhanvien
    Private Sub NHANVIENBindingNavigatorSaveItem_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles NHANVIENBindingNavigatorSaveItem.Click
        Me.Validate()
        Me.NHANVIENBindingSource.EndEdit()
        Me.TableAdapterManager.UpdateAll(Me.DS)
    End Sub

    Private Sub frmNhanvien_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        Me.NHANVIENTableAdapter.Connection.ConnectionString = Module1.connstr
        ' biến connstr đã được khai báo là biến toàn cục trong module, và đã chứa chuỗi kết nối về
        ' CSDL từ chức năng đăng nhập chương trình
        Me.NHANVIENTableAdapter.Fill(Me.DS.NHANVIEN)
    End Sub
End Class
```

Trong C#:
```csharp
private void frmNhanvien_Load(object sender, EventArgs e)
{
    this.NHANVIENTableAdapter.Connection.ConnectionString = Program.connstr;
    this.NHANVIENTableAdapter.Fill(this.DS.NHANVIEN);
}
```

**Lưu ý**: Muốn đưa dữ liệu từ DataTable `DS.NHANVIEN` trong Project về table `Nhanvien` trong cơ sở dữ liệu QLVT, ta dùng lệnh: `Me.NHANVIENTableAdapter.Update(Me.DS.NHANVIEN)`.

*   Tạo 1 `groupBox` trên `frmNhanvien`, kéo các field trong DataTable `NHANVIEN` vào `groupbox`. Ta định nghĩa các thuộc tính của các control theo như bảng sau:

| Control      | Loại control   | Thuộc tính                        | Giá trị                                                                                                |
|--------------|----------------|-----------------------------------|--------------------------------------------------------------------------------------------------------|
| `MANV`       | TextBox        | `Name`                            | `txtMANV`                                                                                              |
| `HO`         | TextBox        | `Name`                            | `txtHO`                                                                                                |
| `TEN`        | TextBox        | `Name`                            | `txtTEN`                                                                                               |
| `PHAI`       | ComboBox       | `Name`                            | `cmbPHAI`                                                                                              |
|              |                | `Items`                           | Nam<br>Nữ                                                                                                |
| `NGAYSINH`   | DateTimePicker | `Name`                            | `dtpNGAYSINH`                                                                                          |
|              |                | `Format`                          | Short                                                                                                  |
| `LUONG`      | TextBox        | `Name`                            | `txtLUONG`                                                                                             |
|              |                | `DataBinding/Advanced/Numeric`    | Decimal Place: 0 <br> (dùng dấu phẩy phân cách hàng ngàn trong Lương)                                   |
| `DIACHI`     | TextBox        | `Name`                            | `txtDIACHI`                                                                                            |
| `GHICHU`     | TextBox        | `Name`                            | `txtGHICHU`                                                                                            |
| `HINH`       | TextBox        | `Name`                            | `txtHINH`                                                                                              |
| `PictureBox` |                | `Name`                            | `PictureBox1`: liên kết với field Hình đang chứa 1 tên đường dẫn chứa hình của nhân viên                |
|              |                | `SizeMode`                        | `StretchImage`                                                                                         |
| `Button`     |                | `Name`                            | `btnHinh`: để chọn file hình cho nhân viên                                                              |
| `GroupBox`   |                | `Name`                            | `Groupbox1`                                                                                            |
|              |                | `Enabled`                         | `false`                                                                                                |

*   Trong DataSource, drag `PHATSINH` trong `NHANVIEN` vào `frmNhanvien` để tạo `PHATSINHBindingsource` (đổi tên thành `bdsPS`): dùng để kiểm tra xem 1 nhân viên đã lập phiếu chưa, nếu đã lập phiếu rồi thì `bdsPS.Count` sẽ dương, và như vậy ta sẽ không cho xóa nhân viên.
*   Thiết kế lại các cột trong `GridControl` `gcNV`: Right click `gcNV`, chọn **Run Designer**:

Chọn **Column, Retrieve Fields** để thấy các cột trên lưới Grid `gcNV`. Ta có thể định nghĩa các thuộc tính cho từng column trên Grid. Các thuộc tính thường hay được sử dụng cho:
*   **Column**:
    *   `Caption`: chuỗi ký tự thay thế cho tên field
    *   `Appearance Cell`: `Back Color`, `Font`, `Fore Color`, `Text Option`: các thuộc tính này để định dạng các ô trong Grid
    *   `Appearance Header`: `Back Color`, `Font`, `Fore Color`, `Text Option`: các thuộc tính này để định dạng các ô của tiêu đề cột
    *   `Display Format`
    *   `Visible`
    *   `Width`: độ rộng của cột
    *   `Option / Option Column`: `AllowEdit`, `AllowGroup`
*   **GridView**: qui định các tính năng hiển thị trên `GridControl`
    *   Chọn `GridView`: `Option View / Show Auto View Row = True`: cho phép xuất hiện dòng để user có thể lọc dữ liệu theo từng cột ngay trên lưới Grid Control
    *   Chọn `GridView`: `Option View / Column Header AutoHeight = True`: tự động điều chỉnh độ cao của tiêu đề cột cho phù hợp với kích cỡ chữ của tiêu đề.
    *   Chọn `GridView`: `Option View / ShowGroupPanel=True`: cho phép kéo 1 cột để nhóm số liệu theo cột đó.
*   **Trong C#**:
    *   Muốn trả về số các dòng trong `GridView` `gvData`: `gvData.DataRowCount`
    *   Muốn lấy giá trị của ô ở dòng `i` trên cột `MANV`: `gvData.GetRowCellValue(i, "MANV").ToString().Trim()`
*   Nếu ta muốn khóa toàn bộ Grid Control thì `gcNV.Enabled = false`

Ta tiến hành chạy thử để kiểm tra xem dữ liệu đã được đưa từ table `Nhanvien` vào form `frmNhanvien` chưa: ấn phím `F5`.

#### B2. Code cho từng nút lệnh: (ngôn ngữ lập trình Visual Basic)
```vbnet
Public Class frmNhanvien
    Dim vitri As Int32 = 0

    Private Sub frmNhanvien_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        'TODO: This line of code loads data into the 'DS.PHATSINH' table. You can move, or remove it, as needed.
        Me.NHANVIENTableAdapter.Connection.ConnectionString = Module1.connstr
        Me.NHANVIENTableAdapter.Fill(Me.DS.NHANVIEN)
        Me.PHATSINHTableAdapter.Connection.ConnectionString = Module1.connstr
        Me.PHATSINHTableAdapter.Fill(Me.DS.PHATSINH)
        If bdsNV.Count = 0 Then
            btnXoa.Enabled = False
        End If
    End Sub

    Private Sub txtMANV_TextChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles txtMANV.TextChanged
        If txtMANV.Text.Trim = "" Then Exit Sub
        On Error GoTo Loi
        PictureBox1.Image = Image.FromFile(txtHINH.Text)
        Exit Sub
Loi:
        PictureBox1.Image = Image.FromFile("C:\Users\vaio\Documents\Visual Studio 2010\Projects\QLVT\QLVT\HinhNhanVien\Tulips.jpg")
    End Sub

    Private Sub btnThem_ItemClick(ByVal sender As System.Object, ByVal e As DevExpress.XtraBars.ItemClickEventArgs) Handles btnThem.ItemClick
        '  On Error Resume Next
        vitri = bdsNV.Position
        GroupBox1.Enabled = True
        gcNV.Enabled = False
        bdsNV.AddNew()
        cmbPHAI.Text = "Nam"
        txtLUONG.Text = "5000000"
        '   bdsNV.Item(bdsNV.Position)("NGAYVAOLAM") = Date.Today

        btnThem.Enabled = False : btnSua.Enabled = False : btnXoa.Enabled = False
        btnInDSNV.Enabled = False : btnThoat.Enabled = False
        btnGhi.Enabled = True : btnPhuchoi.Enabled = True : btnRefresh.Enabled = True

        txtMANV.Focus()
    End Sub

    Private Sub btnSua_ItemClick(ByVal sender As System.Object, ByVal e As DevExpress.XtraBars.ItemClickEventArgs) Handles btnSua.ItemClick
        btnThem.Enabled = False : btnSua.Enabled = False : btnXoa.Enabled = False
        btnInDSNV.Enabled = False : btnThoat.Enabled = False
        btnGhi.Enabled = True : btnPhuchoi.Enabled = True : btnRefresh.Enabled = True
        GroupBox1.Enabled = True
        gcNV.Enabled = False
        vitri = bdsNV.Position
    End Sub

    Private Sub btnGhi_ItemClick(ByVal sender As System.Object, ByVal e As DevExpress.XtraBars.ItemClickEventArgs) Handles btnGhi.ItemClick
        If txtHO.Text.Trim = "" Then
            MsgBox("Họ nhân viên không được thiếu. ", MsgBoxStyle.Information)
            txtHO.Focus()
            Exit Sub
        End If
        If txtTEN.Text.Trim = "" Then
            MsgBox("Tên nhân viên không được thiếu. ", MsgBoxStyle.Information)
            txtTEN.Focus()
            Exit Sub
        End If

        If txtLUONG.Text.Trim = "" Then txtLUONG.Text = 0
        
        If CDbl(txtLUONG.Text) <= 0 Then
            MsgBox("Lương phải có và là số dương. Bạn xem lại ", MsgBoxStyle.Information)
            txtLUONG.Focus()
            Exit Sub
        End If
        If CDbl(txtLUONG.Text) < 5000000 Or CDbl(txtLUONG.Text) > 20000000 Then
            MsgBox("Lương phải từ 5,000,000 đến 20,000,000.", MsgBoxStyle.Information)
            txtLUONG.Focus()
            Exit Sub
        End If

        Try
            bdsNV.EndEdit()
            bdsNV.ResetCurrentItem()
            If DS.HasChanges() Then
                Me.NHANVIENTableAdapter.Update(Me.DS.NHANVIEN)
            End If
        Catch ex As Exception
            If (ex.Message.Contains("PRIMARY")) Then
                MsgBox("Mã nhân viên bị trùng.")
            Else
                MsgBox("Lỗi Ghi nhân viên. Bạn kiểm tra lại thông tin nhân viên trước khi ghi" & _
                         vbCrLf & Err.Description & vbCrLf & Err.Source)
            End If
            Exit Sub
        End Try
        btnGhi.Enabled = False : btnPhuchoi.Enabled = False : GroupBox1.Enabled = False
        btnThem.Enabled = True : btnSua.Enabled = True : btnXoa.Enabled = True : btnRefresh.Enabled = True
        btnInDSNV.Enabled = True : btnThoat.Enabled = True : gcNV.Enabled = True
    End Sub

    Private Sub btnXoa_ItemClick(ByVal sender As System.Object, ByVal e As DevExpress.XtraBars.ItemClickEventArgs) Handles btnXoa.ItemClick
        If bdsPS.Count > 0 Then
            MsgBox("Nhân viên bạn muốn xóa đã lập phiếu nhập hoặc phiếu xuất, nên không thể xóa", MsgBoxStyle.OkOnly)
            Exit Sub
        End If

        If (MsgBox("Bạn có thật sự muốn xóa nhân viên này ?", MsgBoxStyle.YesNo) = MsgBoxResult.Yes) Then
            Try
                bdsNV.RemoveCurrent()
                Me.NHANVIENTableAdapter.Update(Me.DS.NHANVIEN)
            Catch ex As Exception
                MsgBox("Lỗi Xóa nhân viên. " & vbCrLf & ex.Message)
                Exit Sub
            End Try
        End If

        If bdsNV.Count = 0 Then btnXoa.Enabled = False
        ' Tùy biến nút lệnh
    End Sub

    Private Sub btnPhuchoi_ItemClick(ByVal sender As System.Object, ByVal e As DevExpress.XtraBars.ItemClickEventArgs) Handles btnPhuchoi.ItemClick
        bdsNV.CancelEdit()
        bdsNV.Position = vitri
        gcNV.Enabled = True
        GroupBox1.Enabled = False
        ' Tùy biến nút lệnh
    End Sub

    Private Sub btnRefresh_ItemClick(ByVal sender As System.Object, ByVal e As DevExpress.XtraBars.ItemClickEventArgs) Handles btnRefresh.ItemClick
        Me.NHANVIENTableAdapter.Fill(Me.DS.NHANVIEN)
    End Sub

    Private Sub btnThoat_ItemClick(ByVal sender As System.Object, ByVal e As DevExpress.XtraBars.ItemClickEventArgs) Handles btnThoat.ItemClick
        Close()
    End Sub

    Private Sub btnHinh_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnHinh.Click
        Dim path As String
        Dim ofd As OpenFileDialog = New OpenFileDialog()
        ofd.InitialDirectory = Module1.strDefaultPath

        ofd.Title = "Chọn file hình để mở"
        ofd.Filter = "JPG, BMP|*.jpg;*.bmp"
        If (ofd.ShowDialog() = DialogResult.OK) Then
            path = ofd.FileName
            txtHINH.Text = path
        End If
        On Error GoTo Loi
        PictureBox1.Image = Image.FromFile(txtHINH.Text)
        Exit Sub
Loi:
        PictureBox1.Image = Image.FromFile("C:\Users\vaio\Documents\Visual Studio 2010\Projects\QLVT\QLVT\HinhNhanVien\Tulips.jpg")
    End Sub
End Class
```

### c- Tạo Module :
Để chứa các biến, các chương trình con (Sub, Function) sẽ được sử dụng trên toàn bộ Project. Ta Right click trên tên project / **Add / Module**:
________________

```vbnet
Imports System.Data
Imports System.Data.SqlClient
Imports Microsoft.VisualBasic

Module Module1
    Public strDefaultPath As String = "C:\Users\vaio\Documents\Visual Studio 2010\Projects\QLVT_VB\QLVT\HinhNhanVien"
    Public strNoPicture As String = strDefaultPath + "\NoPic.jpg"
    Public conn As New SqlConnection
    Public ConnStr As String
    Public mlogin As String = "sa"
    Public mPass As String = "123"
    
    Public servername As String = "THU-PC"
    Public Function KetNoi() As Int32
        If conn.State = ConnectionState.Open Then conn.Close()
        Try
            ConnStr = "Data Source=" & servername & ";Initial Catalog=QLVT;User ID=" & mlogin & ";Password=" & mPass
            conn.ConnectionString = ConnStr
            conn.Open()
            KetNoi = 1
        Catch ex As Exception
            MsgBox("Lỗi kết nối cơ sở dữ liệu. " & vbCrLf & "Bạn xem lại user name và password.")
            KetNoi = 0
        End Try
    End Function

    Public Function ExecSqlDataReader(ByVal strLenh As String) As SqlDataReader
        Dim cmd As New SqlCommand
        cmd.Connection = conn
        cmd.CommandType = CommandType.Text
        cmd.CommandText = strLenh
        Module1.KetNoi()
        Try
            ExecSqlDataReader = cmd.ExecuteReader
            conn.Close()
        Catch ex As SqlException
            MsgBox("Lỗi thực thi câu lệnh: " & vbCrLf & _
                    strLenh & vbCrLf & ex.Message, MsgBoxStyle.OkOnly)
        End Try
    End Function

    Public Function ExecSqlDataTable(ByVal strLenh As String) As DataTable
        Dim da As New SqlDataAdapter(strLenh, conn)
        Dim dt As New DataTable
        Module1.KetNoi()
        Try
            da.Fill(dt)
            ExecSqlDataTable = dt
        Catch ex As SqlException
            MsgBox("Lỗi thực thi câu lệnh: " & vbCrLf & _
                    strLenh & vbCrLf & ex.Message, MsgBoxStyle.OkOnly)
        End Try
    End Function

    Public Sub ExecNonQuery(ByVal strLenh As String)
        Dim cmd As New SqlCommand
        cmd.Connection = conn
        cmd.CommandType = CommandType.Text
        cmd.CommandText = strLenh
        Module1.KetNoi()
        Try
            cmd.ExecuteNonQuery()
        Catch ex As SqlException
            MsgBox("Lỗi: " & ex.Message, MsgBoxStyle.OkOnly)
        End Try
    End Sub
End Module
```

## 4. Tạo Subform:
Subform là dạng form cho phép nhập dữ liệu cùng lúc vào 2 tables trở lên, ví dụ như ta tạo form `frmLapPhieu` sẽ cho phép nhập dữ liệu vào table `PhatSinh` và `CT_PhatSinh`.
Dạng form này sẽ có 2 phần: phần Main hiển thị dữ liệu của table đầu 1 (`PhatSinh`), phần Sub hiển thị dữ liệu của table đầu nhiều (`CT_PhatSinh`) và chỉ hiển thị các mẫu tin có liên quan đến khóa chính (Số phiếu) trong table đầu 1.

*   Ta Add/ Window Form tên `frmLapPhieu`.
*   Trong DataSet, ta tạo các DataTable: `Phatsinh`, `CT_PhatSinh`, `Kho`, `VatTu`, `HotenNV` (SQL: `SELECT HO + ' ' + TEN + ' - ' + LTRIM(STR(MANV)) AS HOTEN, MANV FROM NHANVIEN ORDER BY TEN, HO`).
*   Ta thiết kế Form `frmLapPhieu` có dạng sau:

Các Controls trên form sẽ có các thuộc tính quan trọng sau:

| Control                                 | Loại control            | Thuộc tính                | Giá trị                                                                                                    |
|-----------------------------------------|-------------------------|---------------------------|------------------------------------------------------------------------------------------------------------|
| Menu Bar                                | `BarManager1`           | `Name`                    | `Bar1`                                                                                                     |
| Lưới chứa các phiếu                     | `GridControl`           | `Name`                    | `gcPS`                                                                                                     |
|                                         |                         | `DataSource`              | `bdsPS`                                                                                                    |
|                                         |                         | `Dock`                    | `Top`                                                                                                      |
| Group chứa các control của `PhatSinh`   | `GroupControl`          | `Name`                    | `GroupBox1`                                                                                                |
|                                         |                         | `Dock`                    | `Left`                                                                                                     |
|                                         |                         | Các control trong GroupBox | có liên quan đến table `PhatSinh` đều phải binding đến các field trong `Phatsinh` qua thuộc tính `DataBinding/Text` |
| Chi tiết phiếu                          | `DataGridView`          | `Name`                    | `dgvCTPS`                                                                                                  |
|                                         |                         | `DataSource`              | `bdsCTPS`                                                                                                  |
|                                         |                         | `Dock`                    | `Fill`                                                                                                     |
|                                         |                         | `AllowUserToAddRows`      | `False`                                                                                                    |
|                                         |                         | `AllowUserToDeleteRows`   | `False`                                                                                                    |
| Phieu                                   | `TextBox`               | `Name`                    | `txtPhieu`                                                                                                 |
| NgayLap                                 | `DateTimePicker`        | `Name`                    | `dtpNGAYSINH` (Note: name seems like a copy-paste, likely should be `dtpNgayLap`)                            |
|                                         |                         | `Format`                  | `Short`                                                                                                    |
|                                         |                         | `DataBinding/Value`       | `bdsPS - Ngay`                                                                                             |
| Loai                                    | `ComboBox`              | `Name`                    | `cmbLoai`                                                                                                  |
|                                         |                         | `Items`                   | Nhập<br>Xuất                                                                                               |
| Nhacungcap                              | `Label`<br>`Textbox`     | `Name`<br>`Name`          | `lblHoten` (Note: likely `lblNhaCungCap`)<br>`txtHoten` (Note: likely `txtNhaCungCap`)                     |
| Kho                                     | `comboBox`<br>`TextBox` | `Name`                    | `cmbTenKho`                                                                                                |
|                                         |                         | `DataSource`              | `bdsKho`                                                                                                   |
|                                         |                         | `DisplayMember`           | `Tenkho`                                                                                                   |
|                                         |                         | `ValueMember`             | `Makho`                                                                                                    |
|                                         |                         | `Selected Value`          | `bdsPS - Makho`                                                                                            |
|                                         |                         | `DataBinding/Text`        | `None` (for ComboBox)                                                                                      |
|                                         |                         | `Name`                    | `txtMaKho` (for TextBox)                                                                                   |
|                                         |                         | `DataBinding/Text`        | `bdsPS - Makho` (for TextBox)                                                                              |
| Nhanvien                                | `ComboBox`              | `Name`                    | `cmbHotenNV` <br> (Tương tự như Kho)                                                                        |
| Lydo                                    | `TextBox`               | `Name`                    | `txtLydo`                                                                                                  |
| Các Nút lệnh                            | `Button` Thêm<br>`Button` Ghi<br>`Button` Xóa<br>`Button` Tải lại<br>`Button` ChiTietPhieu<br>`Button` Thoát | `Name` | `btnThem` <br>`btnGhi`<br>`btnXoa`<br>`btnRefresh`<br>`btnChiTietPhieu`<br>`btnThoat`                        |
| ShortCut Menu.                          | `ContextMenuStrip`      | `Name`                    | `ContextMenuStrip1`                                                                                        |
|                                         | Thêm vật tư             | `Name`                    | `btnThemVT`                                                                                                |
|                                         | Xóa vật tư              | `Name`                    | `btnXoaVT`                                                                                                 |
|                                         | Ghi vật tư              | `Name`                    | `btnGhiVT`                                                                                                 |

Muốn Form hiểu `ContextMenuStrip`, ta cho `frmLapPhieu.ContextMenuStrip = ContextMenuStrip1`.
Ta hiệu chỉnh các cột trong `dgvCTPS`: Right click / **Edit Column**.

Phần code, ta viết tương tự như Form `frmNhanvien`, nhưng lưu ý ta có đoạn code thêm Phiếu, xóa Phiếu, thêm vật tư vào phiếu, xóa vật tư khỏi phiếu riêng.