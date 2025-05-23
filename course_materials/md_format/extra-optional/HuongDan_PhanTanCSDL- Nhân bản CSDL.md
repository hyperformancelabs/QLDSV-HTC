# Chuẩn bị :
*   Ta tạo 1 folder **D:\ReplData** để chứa các dữ liệu trao đổi trong quá trình update dữ liệu từ các phân mảnh về cơ sở dữ liệu gốc, và từ cơ sở dữ liệu gốc đến các phân mảnh
*   Tiến hành cho folder này là 1 snapshot folder: thực chất là 1 shared folder trong Windows, cho phép các users được quyền read/write (giả sử shared folder có tên **\\\\THU-PC\\REPLDATA**)
    Right click trên folder **REPLDATA**, chọn **Properties**, chọn tab **Sharing – Share**

    ![Image Placeholder 1]()

    Chọn **Everyone**, click **Add**, và chọn quyền **Read/Write** như trong hình. Cuối cùng, click nút lệnh **Share**.

    ![Image Placeholder 2]()

## 1. To configure distribution

1.  In Microsoft SQL Server Management Studio, connect to the server that will be the Distributor (in many cases, the Publisher and Distributor are the same server), and then expand the server node.
2.  Right-click the **Replication** folder, and then click **Configure Distribution**.

    ![Image Placeholder 3]()

3.  Follow the **Configure Distribution Wizard** to:
    *   Select a Distributor. To use a local Distributor, select '`<ServerName>` will act as its own Distributor; SQL Server will create a distribution database and log.'

    *   To use a remote Distributor, select 'Use the following server as the Distributor', and then select a server. The server must already be configured as a Distributor, and the Publisher must be enabled to use the Distributor.

    ![Image Placeholder 4]()

    *   If you select a remote Distributor, you must enter a password on the **Administrative Password** page for connections made from the Publisher to the Distributor. This password must match the password specified when the Publisher was enabled at the remote Distributor.

    *   Specify a root snapshot folder (for a local Distributor). The snapshot folder is simply a directory that you have designated as a share; agents that read from and write to this folder must have sufficient permissions to access it. Each Publisher that uses this Distributor creates a folder under the root folder, and each publication creates folders under the Publisher folder in which to store snapshot files.

    ![Image Placeholder 5]()

    *   Specify the distribution database (for a local Distributor). The distribution database stores metadata and history data for all types of replication and transactions for transactional replication.

    *   Optionally enable other Publishers to use the Distributor. If other Publishers are enabled to use the Distributor, you must enter a password on the **Distributor Password** page for connections made from these Publishers to the Distributor.

    ![Image Placeholder 6]()

    *   Optionally script configuration settings. For more information, see Scripting Replication.

    ![Image Placeholder 7]()
    ![Image Placeholder 8]()
    ![Image Placeholder 9]()
    ![Image Placeholder 10]()

> **Note :** Để DISABLE các Server Publisher và Distributor, ta thực hiện các bước :

    ![Image Placeholder 11]()
    ![Image Placeholder 12]()
    ![Image Placeholder 13]()
    ![Image Placeholder 14]()
    ![Image Placeholder 15]()
    ![Image Placeholder 16]()
    ![Image Placeholder 17]()

## B. Create publications
Create publications and define articles with the **New Publication Wizard**. After a publication is created, view and modify publication properties in the **Publication Properties - <Publication>** dialog box.

    ![Image Placeholder 18]()
    ![Image Placeholder 19]()

### To create a publication and define articles
1.  Connect to the Publisher in Microsoft SQL Server Management Studio, and then expand the server node.
2.  Expand the **Replication** folder, and then right-click the **Local Publications** folder.
3.  Click **New Publication**.

    ![Image Placeholder 20]()

4.  Follow the pages in the **New Publication Wizard** to:

    ![Image Placeholder 21]()
    ![Image Placeholder 22]()
    ![Image Placeholder 23]()
    ![Image Placeholder 24]()
    ![Image Placeholder 25]()
    ![Image Placeholder 26]()

    > **Lưu ý:** bỏ chọn table `sysdiagrams`

    ![Image Placeholder 27]()
    ![Image Placeholder 28]()

    Chọn **Add Filter**, chọn **CHINHANH** và đưa vào điều kiện phân tán như hộp thoại dưới đây:

    ![Image Placeholder 29]()

    Click **OK**, để thoát ra ngoài.
    Sau đó, ta chọn **CHINHANH**, chọn **Add**, **Add Join to Extend the Selected Filter** để chọn **NHANVIEN** là quan hệ dẫn xuất theo **CHINHANH** như hình sau:

    ![Image Placeholder 30]()

    Tương tự, ta tạo các phân mảnh ngang còn lại như trong hình sau:

    ![Image Placeholder 31]()

    click **OK** để qua bước kế:

    ![Image Placeholder 32]()
    ![Image Placeholder 33]()
    ![Image Placeholder 34]()
    ![Image Placeholder 35]()
    ![Image Placeholder 36]()
    ![Image Placeholder 37]()
    ![Image Placeholder 38]()

    *   Ta đặt tên cho publication. Click chọn **View Snapshot Agent Status** để xem trạng thái của Snapshot Agent.

    ![Image Placeholder 39]()
    ![Image Placeholder 40]()

*   **Start** : Cho Snapshot Agent hoạt động
    *   **Monitor** : mở window theo dõi quá trình đồng bộ dữ liệu.

## C. Tạo Subscription

Right Click trên 1 publication, chọn **New Subscriptions …**

    ![Image Placeholder 41]()
    ![Image Placeholder 42]()
    ![Image Placeholder 43]()

Click chọn nút lệnh **Add SQL Server Subscriber** để chỉ định 1 Server làm nơi chứa cơ sở dữ liệu phân tán. Sau đó, ta chỉ định tiếp 1 cơ sở dữ liệu làm nơi chứa các Article (nên là 1 cơ sở dữ liệu mới).