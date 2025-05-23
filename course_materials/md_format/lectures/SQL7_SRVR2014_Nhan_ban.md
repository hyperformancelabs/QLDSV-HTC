# Chương 7. Nhân bản dữ liệu

## I. KHÁI NIỆM
Nhân bản dữ liệu cho phép ta phân bố các bản dữ liệu từ 1 source đến các hệ thống target 1 cách tự động. Nhân bản dữ liệu trong SQL Server dựa trên mô hình push-pull. Trong mô hình này, tiến trình nhân bản sẽ:
- Server nguồn đẩy dữ liệu được nhân bản đến server đích, hoặc
- Server đích kéo dữ liệu từ server nguồn về.

Trong SQL Server, server nguồn được gọi là **Publisher**, server đích được gọi là **Subscriber**.
Khi nhân bản dữ liệu, ta phải cân nhắc chọn kiểu nhân bản nào dựa vào 2 yếu tố: dữ liệu tự động đồng bộ giữa các site (Nhất quán trong giao tác) hoặc dữ liệu chỉ đồng bộ theo nhu cầu của user (tự quản).

## II. CÁC THÀNH PHẦN CƠ BẢN TRONG REPLICATION
1.  **Article**: là 1 đơn vị dữ liệu cơ sở. Article tiêu biểu cho đối tượng dữ liệu được nhân bản. 1 article có thể là dữ liệu từ 1 table hay 1 đối tượng cơ sở dữ liệu (toàn bộ table hay 1 stored procedure, view, UDF). Tất cả articles phải thuộc về 1 publication.
2.  **Distributor**: là hệ thống SQL Server có trách nhiệm chuyển dữ liệu được nhân bản giữa **Publisher** và **Subscriber**.
    Đối với lượng dữ liệu nhân bản nhỏ, **Distributor** và **Publisher** luôn thuộc về 1 hệ thống; trong trường hợp ngược lại, **Distributor** và **Publisher** thuộc 2 Server khác nhau.
3.  **Publication**: đại diện cho 1 nhóm các article. Khái niệm **Publication** cho phép dữ liệu và đối tượng có liên hệ được nhóm lại với nhau để nhân bản.
4.  **Publisher**: là Server chứa cơ sở dữ liệu gốc để nhân bản. Một SQL Server chỉ có 1 **Publisher**. **Publisher** trích thông tin trong cơ sở dữ liệu sẽ được nhân bản và đưa thông tin đó đến **Distributor** – thường là nằm trên cùng 1 hệ thống.
5.  **Subscription**: database sẽ chứa các articles trong publication.
6.  **Subscriber**: là 1 SQL Server, nó nhận dữ liệu đã được định nghĩa trong **Publication**. Một scenario replication chỉ có 1 **Publisher**, nhưng có thể có nhiều **Subscriber**.

## III. CÁC KIỂU NHÂN BẢN DỮ LIỆU TRONG SQL SERVER :
1.  **Snapshot Replication**: tạo 1 bản copy dữ liệu được nhân bản tại 1 thời điểm xác định; toàn bộ dữ liệu được đưa tới **Subscriber**. Loại nhân bản này thích hợp trong các tình huống không cần tính nhất quán dữ liệu cao.
    Ví dụ: Khi ta có 1 hệ thống SQL Server đóng vai trò như 1 hệ thống xử lý giao tác trực tuyến (OLTP- Online Transactional Processing) và 1 hệ thống SQL Server thứ 2 đóng vai trò như hệ hỗ trợ quyết định, và hệ hỗ trợ quyết định này không đòi hỏi dữ liệu mới nhất mà chỉ cần cập nhật dữ liệu vào cuối ngày, thì trong trường hợp này ta dùng snapshot replication.
2.  **Transactional replication**: dùng transaction log để nhân bản các giao tác cá nhân giữa **Publisher** và **Subscriber**. Transaction log của **Publisher** nắm bắt các thay đổi dữ liệu, sau đó sẽ áp dụng các thay đổi đó đến **Subscriber** theo đúng trình tự mà chúng thực hiện. Với **Transactional replication**, sự chuyển dữ liệu giữa **Publisher** và **Subscriber** có thể xảy ra hoặc là liên tục, hoặc là định kỳ trong 1 khoảng thời gian.
    Ví dụ: Trong tình huống có 2 nơi cùng đặt hàng từ 1 cơ sở dữ liệu mà có chung tồn kho và cả 2 nơi đều cần dữ liệu mới nhất thì ta sẽ dùng **Transactional replication**.
3.  **Merge**: dạng nhân bản này theo dõi các thay đổi trong cả 2 cơ sở dữ liệu nguồn và đích, và thực hiện sự đồng bộ về dữ liệu giữa **Subscriber** và **Publisher** khi cơ sở dữ liệu được nhân bản.
    Ví dụ: Áp dụng **Merge replication**, 1 chi nhánh công ty có thể thực hiện các chức năng trong khi disconnect hoàn toàn với cơ sở dữ liệu đang đặt ở văn phòng trung tâm . Trong ngày, văn phòng chi nhánh dùng cơ sở dữ liệu của mình để thực hiện các công việc. Vào cuối ngày, văn phòng chi nhánh sẽ kết nối với văn phòng trung tâm và merge với cơ sở dữ liệu tại trung tâm về tình hình bán, đặt hàng, thông tin khách hàng mới đã phát sinh trong ngày. Tương tự, các thay đổi đã thực hiện đến khách hàng và tín dụng sẽ được merge với cơ sở dữ liệu tại văn phòng chi nhánh.

## IV. CÀI ĐẶT MERGE REPLICATION:
(xem file Hướng dẫn nhân bản DB)