# TẠO BÁO CÁO SỐ LIỆU VỚI XtraReport

Phần mềm XtraReport trong DevExpress giúp ta thiết kế báo biểu một cách dễ dàng và nhanh chóng. Muốn thiết kế một report, ta phải qua các bước sau:
1.  Phác họa một mẫu thiết kế nháp trên giấy với các yêu cầu cụ thể: Tiêu đề báo cáo, mẫu báo cáo có các cột nào, các mẫu tin cần hiển thị, phần nào chỉ in 1 lần ở đầu trang 1 hoặc ở cuối báo cáo (Report Header/ Report Footer), phần nào sẽ in lại ở đầu/cuối mỗi trang (Page Header/Page Footer)
2.  Tạo một view hoặc một stored procedure trong SQL Server đáp ứng các cột và điều kiện của mẫu báo cáo
3.  Dùng XtraReport để thiết kế Report dựa vào View hoặc SP đã tạo ở bước 2
4.  Tạo một Form chứa đối tượng ..., đối tượng này sẽ liên kết với Report đã thiết kế ở bước 3 qua thuộc tính ReportSource. Nếu ta đang thiết kế Report có tham số thì trên form sẽ có thêm một số controls đóng vai trò giao tiếp với người dùng để người dùng cung cấp giá trị cho tham số trong Report.

XtraReport có 2 loại : Standard, CrossTab. Loại Standard lại chia thành 3 dạng ;
*   Report không tham số
*   Report có tham số
*   Report có nhóm số liệu theo từng nhóm.
Trong phần này ta sẽ thiết kế báo cáo số liệu qua tham số.

- Ta chuyển .Net Framework của Project qua Framework 4 như sau : vào trang thuộc tính của Project, chọn Application (trong C#):

  `[Image placeholder: Project properties, Application tab showing .NET Framework selection]`

1.  **Standard Report có tham số:** Giả sử ta muốn tạo report in ra danh sách các phiếu do một nhân viên có mã @Manv đã lập thuộc loại @loai trong năm @nam theo mẫu dưới đây. Theo ví dụ này thì tham số của Report là mã nhân viên, loại và năm lập phiếu. Danh sách các phiếu khi in ra sẽ được sắp thứ tự theo thời gian lập phiếu.
    1.  Mẫu báo cáo ta sẽ thiết kế.

        `[Image placeholder: Sample report layout - "DANH SÁCH PHIẾU NHẬP/XUẤT NHÂN VIÊN LẬP TRONG NĂM XXXX", Họ tên NV: Nguyễn Văn A, Ngày lập: ..., Số phiếu, Ngày, Tên vật tư, Số lượng, Đơn giá, Trị giá, Tổng cộng]`

    2.  Trong cơ sở dữ liệu QLVT, ta tạo SP tên sp_PhieuNvLapTrongNamTheoLoai như sau:
        ```sql
        CREATE PROC [dbo].[sp_PhieuNvLapTrongNamTheoLoai]
        @MANV INT, @LOAI CHAR, @NAM INT AS
        SELECT PS.PHIEU, NGAY, TENVT , SOLUONG ,DONGIA , TRI_GIA = SOLUONG * DONGIA
        FROM (SELECT PHIEU, NGAY FROM PHATSINH
        WHERE MANV = @MANV AND LOAI =@LOAI AND YEAR(NGAY)=@NAM) PS,
        CT_PHATSINH CT, VATTU VT
        WHERE PS.PHIEU=CT.PHIEU AND CT.MAVT=VT.MAVT ORDER BY NGAY , PS.PHIEU
        ```

    3.  Thiết kế Report:
        Trong Project QLVT, Right click trên tên Project / Add / New Item. Ta chọn Reporting / DevExpress Report Wizard , sau đó nhập vào tên của report

        `[Image placeholder: Add New Item dialog, selecting DevExpress Report Wizard, naming the report]`

        Chọn Add:

        `[Image placeholder: DevExpress Report Wizard - Select Report Type (Standard)]`

        `[Image placeholder: DevExpress Report Wizard - Select Data Source Type (Database)]`

        `[Image placeholder: DevExpress Report Wizard - Specify a Connection String]`

        `[Image placeholder: DevExpress Report Wizard - Choose a Query or Stored Procedure (showing stored procedure selected)]`

        Chọn Stored Procedure đã viết ở bước 2

        `[Image placeholder: DevExpress Report Wizard - Configure Stored Procedure Parameters (@MANV, @LOAI, @NAM)]`

        Ta điền các giá trị cho các tham số @MANV, @LOAI, @NAM vào (lưu ý: ta nên nhập dữ liệu cho các tham số sao cho khi chạy report sẽ có thông tin truy vấn được), click Next

        `[Image placeholder: DevExpress Report Wizard - Select Fields to Display in a Report]`

        Chuyển các fields từ “Available Fields” qua “Fields to display in a report”. Lưu ý : chuyển cho đúng thứ tự các cột trong báo cáo.

        `[Image placeholder: DevExpress Report Wizard - Add a Grouping Level (empty)]`

        Nếu Report có in theo từng nhóm số liệu trong 1 field thì đưa field đó qua. Trong ví dụ này, ta không có group số liệu khi in nên để trống cột bên phải.

        `[Image placeholder: DevExpress Report Wizard - Choose a Report Layout (Tabular selected)]`

        Chọn Tabular theo như hình.

        `[Image placeholder: DevExpress Report Wizard - Choose a Report Style]`

        `[Image placeholder: DevExpress Report Wizard - Specify the Report Title]`

        Sau khi click nút lệnh Finish, ta sẽ có báo cáo sau:

        `[Image placeholder: Initial XtraReport design surface after wizard completion]`

        Click chọn nút Report Task :

        `[Image placeholder: XtraReport smart tag (Report Tasks)]`

        Ta tạo thêm các XrLabel như trong báo cáo (lblTieuDe, lblHoten), và sau này ta sẽ đưa dữ liệu từ phần Form vào 2 label lblTieuDe, lblHoten. Các label này phải có thuộc tính Modifiers= Public thì Form sau này mới giao tiếp với nó được.
        *   Kẻ ô : Ta chọn các Cell trong Table : Border : All
        *   Text Alignment : canh dữ liệu
        *   Muốn tạo Label chứa Tổng Trị giá của báo cáo , ta Insert Report Footer vào báo cáo, sau đó kéo TRIGIA trong Field List vào Report Footer (như trong hình). Sau đó, ta vào trang Task của TổngTriGia , click chọn ... ở Summary

            `[Image placeholder: Report Designer showing TRIGIA field dragged to Report Footer and Summary task selected]`

        Chọn các giá trị như trong hình:

        `[Image placeholder: Summary Editor dialog for TRIGIA field (Sum, Running: Report)]`

        *   Giả sử ta muốn tạo calculated Field (Field ta tính toán trong Xtra report dựa vào các Field đang có trong báo cáo), ví dụ như ta muốn tính TriGia = Soluong * Dongia:

            `[Image placeholder: Field List, right-click, Add Calculated Field]`

            `[Image placeholder: CalculatedField Collection Editor - Properties for new calculated field (Name: TriGia_Calc, FieldType: Decimal, Expression: [SOLUONG] * [DONGIA])]`

        *   Để tự động load dữ liệu về Report, Trong phần Code của XtraReport ta nhập vào Phương thức khởi tạo sau để khi ta tạo đối tượng trên XtraReport thì sẽ tự động tải dữ liệu mới nhất theo tham số về report.

        TRONG VB :
        ```vb.net
        Public Class Xrpt_PhieuNvLapTrongNamTheoLoai

        Public Sub New(manv As Int32, loai As String, nam As Int32)
            InitializeComponent()
            Me.SqlDataSource1.Queries(0).Parameters(0).Value = manv
            Me.SqlDataSource1.Queries(0).Parameters(1).Value = loai
            Me.SqlDataSource1.Queries(0).Parameters(2).Value = nam
            Me.SqlDataSource1.Fill()
        End Sub
        End Class
        ```

        TRONG C# :
        ```csharp
        public partial class Xrpt_PhieuNvLapTrongNamTheoLoai : DevExpress.XtraReports.UI.XtraReport
        {
            public Xrpt_PhieuNvLapTrongNamTheoLoai (int manv , string loai , int nam )
            {
                InitializeComponent();
                this.sqlDataSource1.Connection.ConnectionString = Program.connstr;
                this.sqlDataSource1.Queries[0].Parameters[0].Value = manv;
                this.sqlDataSource1.Queries[0].Parameters[1].Value = loai;
                this.sqlDataSource1.Queries[0].Parameters[2].Value = nam;
                this.sqlDataSource1.Fill();
            }
        }
        ```

    4.  Tạo Form giao tiếp với user để user nhập dữ liệu trước khi in báo cáo: Ta thêm một form mới có tên XfrmPhieuNvLapTrongNamTheoLoai để cung cấp các tham số cho report, cụ thể là mã nhân viên, loại phiếu, năm lập phiếu. Ta thiết kế form có dạng sau:
        *   Trước hết, ta tạo một DataTable để chứa một danh sách nhân viên gồm 2 cột Hoten, Manv . DataTable này dùng để hỗ trợ cho việc chọn một nhân viên để lấy ra mã nhân viên cung cấp cho tham số manv. Cách làm: Mở cửa số DataSet / Right click / Add / TableAdapter

            `[Image placeholder: DataSet Designer - Right-click, Add, TableAdapter]`

            `[Image placeholder: TableAdapter Configuration Wizard - Choose Your Data Connection]`

            `[Image placeholder: TableAdapter Configuration Wizard - Choose a Command Type (Use SQL statements)]`

            `[Image placeholder: TableAdapter Configuration Wizard - Enter a SQL Statement (SELECT MANV, HO + ' ' + TEN AS HOTEN FROM NHANVIEN)]`

        Thiết kế Form giao tiếp với người dùng như sau:

        `[Image placeholder: Windows Form designed for report parameter input (ComboBox for Hoten NV, TextBox for MANV, ComboBox for Loai Phieu, ComboBox for Nam, Button Preview, Button Thoat)]`

        *   Ta định nghĩa các thuộc tính của các control theo như bảng sau:

        | Control      | Loại control | Thuộc tính   | Giá trị          |
        |--------------|--------------|--------------|------------------|
        | Họ tên NV    | ComboBox     | Name         | cmbHoten         |
        |              |              | DataSource   | bdsNV            |
        |              |              | DisplayMember| HOTEN            |
        |              |              | ValueMember  | MANV             |
        | MANV         | TextBox      | Name         | txtManv          |
        | LOAI PHIEU   | ComboBox     | Name         | cmbLoai          |
        |              |              | Items        | Nhập<br>Xuất    |
        | Năm          | ComboBox     | Name         | cmbNam           |
        |              |              | Items        | 2007<br>2008<br>2009 |
        | Preview      | Button       | Name         | btnPreview       |
        | Thoát        | Button       | Name         | btnThoat         |

        Code của Form XfrmPhieuNvLapTrongNamTheoLoai
        Trong VB:
        ```vb.net
        Imports DevExpress.XtraReports.UI
        Public Class Xfrm_PhieuNvLapTrongNamTheoLoai

        Private Sub Xfrm_PhieuNvLapTrongNamTheoLoai_Load(sender As System.Object, e As System.EventArgs) Handles MyBase.Load
            'TODO: This line of code loads data into the 'DS.DSNV' table. You can move, or remove it, as needed.
            Me.DSNVTableAdapter.Fill(Me.DS.DSNV)
            cmbLoai.SelectedIndex = 0
            cmbNam.SelectedIndex = 0
        End Sub

        Private Sub cmbHoten_SelectedIndexChanged(sender As System.Object, e As System.EventArgs) Handles cmbHoten.SelectedIndexChanged
            txtManv.Text = cmbHoten.SelectedValue.ToString
        End Sub

        Private Sub btnPreview_Click(sender As Object, e As EventArgs) Handles btnPreview.Click
            Dim manv As Int32 = CInt(TXTMANV.Text)
            Dim rpt As Xrpt_PhieuNvLapTrongNamTheoLoai
            rpt = New Xrpt_PhieuNvLapTrongNamTheoLoai(manv, cmbLoai.Text.Substring(0, 1), CInt(cmbNam.Text))
            rpt.lblTieuDe.Text = "DANH SÁCH PHIẾU " & cmbLoai.Text.ToUpper & " NHÂN VIÊN LẬP TRONG NĂM " & cmbNam.Text
            rpt.lblHoTen.Text = CMBHOTEN.Text

            Dim printTool As New ReportPrintTool(rpt)
            printTool.ShowPreviewDialog()
        End Sub
        ```
        Muốn dùng được ReportPrintTool thì ta phải Imports DevExpress.XtraReports.UI ở đầu file .

        Trong C#:
        ```csharp
        private void btnPreview_Click(object sender, EventArgs e)
        {
            int manv = int.Parse(txtManv.Text);
            Xrpt_PhieuNvLapTrongNamTheoLoai rpt = new Xrpt_PhieuNvLapTrongNamTheoLoai(manv, cmbLoai.Text.Substring(0, 1), int.Parse(cmbNam.Text));

            rpt.lblTieuDe.Text = "DANH SÁCH PHIẾU " + cmbLoai.Text.ToUpper() + " NHÂN VIÊN LẬP TRONG NĂM " + cmbNam.Text;
            rpt.lblHoTen.Text = cmbHoten.Text;

            ReportPrintTool printTool = new ReportPrintTool(rpt);
            printTool.ShowPreviewDialog();
        }
        ```
        Lưu ý : các label lblTieude, lblHoten trong Report phải đổi thuộc tính Modifiers = Public thì trong Form mới truy cập được.

2.  **CROSS-TAB REPORT:** Loại Report này hiển thị dữ liệu theo nhiều chiều. Loại Report này dùng khi số cột của báo cáo không cố định; tiêu đề cột của báo cáo là dữ liệu của 1 field trong mệnh đề Select. Giả sử ta muốn In Bảng điểm tổng kết của một lớp dựa vào mã lớp nhập vào, điểm thi là điểm lớn nhất của các lần thi theo mẫu sau:
    ```
    BẢNG ĐIỂM TỔNG KẾT CUỐI KHÓA LỚP: XXXXXXXXXXXXX – KHÓA HỌC: KHOA: XXXXXXXXXXX
    MASV-Họ tên     Môn học 1     Môn học 2     Môn học 3     Môn học 4     Môn học n
    [Dữ liệu SV1]    [Điểm]        [Điểm]        [Điểm]        [Điểm]        [Điểm]
    [Dữ liệu SV2]    [Điểm]        [Điểm]        [Điểm]        [Điểm]        [Điểm]
    ...
    ```
    Loại Report này dùng Pivot Grid để tạo. Các bước
    1.  Tạo Empty Report với DevExpress : Right click trên Folder Report , Add DevExpress Item / Report Wizard:

        `[Image placeholder: Add New Item dialog, selecting DevExpress Report Wizard]`

        Click chọn OK:

        `[Image placeholder: DevExpress Report Wizard - Select Report Type (Empty Report)]`

        Chọn Empty Report , Finish
    2.  Trong Report Control của thanh ToolBox, kéo thả control XRPivotGrid vào khu vực Details

        `[Image placeholder: Toolbox with XRPivotGrid control highlighted, being dragged to Detail band of report]`

        Click smart tag để mở PivotGrid Tasks, trong DataSource chọn AddReportDataSource để liên kết PivotGrid với sp_BANGDIEMTONGKET

        `[Image placeholder: XRPivotGrid Tasks smart tag - DataSource property with "Add Report Data Source..." selected]`

        `[Image placeholder: Data Source Wizard - Choose Your Data Connection]`

        Chọn ConnectionString tương ứng đến cơ sở dữ liệu chứa SP lấy dữ liệu:

        `[Image placeholder: Data Source Wizard - Choose a Query or Stored Procedure (showing sp_BANGDIEMTONGKET selected)]`

        Chọn SP_BANGDIEMTONGKET:

        `[Image placeholder: Data Source Wizard - Parameters for sp_BANGDIEMTONGKET (e.g., @MALOP)]`

        Click Finish, ta có:

        `[Image placeholder: Report designer with XRPivotGrid control bound to sp_BANGDIEMTONGKET]`

    3.  Thiết kế Cross-Tab : Click chọn Run Designer...
        Chọn Fields, click nút lệnh Retrieve Fields để lấy danh sách các fields trong SP

        `[Image placeholder: XRPivotGrid Designer - Fields tab, Retrieve Fields button highlighted]`

        Qua trang Layout để thiết kế: ta kéo thả các fields vào các vùng Row (MASV, HOTEN), Column(TENMH), DataItem (DIEM)

        `[Image placeholder: XRPivotGrid Designer - Layout tab, showing MASV, HOTEN in Row Area, TENMH in Column Area, DIEM in Data Area]`

        Click nút lệnh Apply, click nút Close đóng cửa sổ Designer . Lúc này, Report có dạng:

        `[Image placeholder: Report designer showing the configured XRPivotGrid structure]`

        Click nút Preview để xem kết quả :

        `[Image placeholder: Report preview showing the Cross-Tab report generated by XRPivotGrid]`

        Mặc định, PivotGrid sẽ dùng hàm Sum để thống kê số liệu. Nếu ta muốn dùng hàm khác, click chọn DataItem (trong ví dụ này là DIEM), chọn thuộc tính Summary Type là MAX

        `[Image placeholder: XRPivotGrid Designer or Properties window - Selecting field DIEM in Data Area, setting SummaryType to Max]`

        Điều chỉnh Layout của Pivot Grid:
        *   Click chọn fieldTENMH : Caption = Môn học
        *   Thay đổi độ rộng các cột, chọn Data Column tương ứng, Width = ...
        *   Định dạng dữ liệu : Data Column tương ứng, Appearance
        *   Bỏ Grand Total : chọn Data Item (DIEM) : cho Options/ Show Grand Total : false

        You can adjust a column's width to fit its content. To do this, handle the Pivot Grid's XRControl.BeforePrint event and call the XRPivotGridField.BestFit method at runtime. You can also use the XRPivotGrid.BestFit method to resize all the columns that correspond to the data and row fields to display all their content.

        ```csharp
        // C# VB (as per original, likely meaning C# and VB examples)
        using System.Drawing.Printing;
        // ...

        private void xrPivotGrid1_BeforePrint(object sender, PrintEventArgs e) {
            xrPivotGrid1.BestFit(fieldProductName1); // Assuming fieldProductName1 is an example field
        }
        ```

        `[Image placeholder: Visual representation of code for BestFit]`

        Specify the Pivot Grid's Print Options

        Use the XRPivotGrid.OptionsPrint property to specify print options and define which Pivot Grid elements are printed.

        *   Disable the PivotGridOptionsPrint.PrintDataHeaders and PivotGridOptionsPrint.PrintFilterHeaders settings to prevent data fields and filter fields' headers from being printed.
        *   Enable the PivotGridOptionsPrint.PrintRowAreaOnEveryPage option to repeat row headers on each document page when the Pivot Grid's layout is divided horizontally across several pages.