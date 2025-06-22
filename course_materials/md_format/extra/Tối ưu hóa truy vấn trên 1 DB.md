# Tối ưu hóa truy vấn trên 1 CSDL

1.  Dùng phép chọn/chiếu trước, phép kết sau

2.  Khử phép kết (nếu được): nếu kết quả in ra có 1 cột mà dữ liệu không thay đổi thì bảng cung cấp dữ liệu cho cột có thể truy vấn riêng.
    **Ví dụ:** In bảng điểm môn @mamh, @malop, lan =@lan

    ```sql
    -- TENLOP   TENMH   MASV   HOTEN   DIEM
    CREATE PROC SP_BDMH
    @malop NVARCHAR(10), @mamh NVARCHAR(10),  @lan INT
    AS
    BEGIN
      SELECT TENLOP, TENMH , SV.MASV , HOTEN=HO+' '+TEN, DIEM
        FROM LOP , SINHVIEN SV, DIEM , MONHOC MH
        WHERE SV.MALOP = @malop  AND DIEM.MAMH = @mamh AND LAN = @lan
          AND LOP.MALOP =SV.MALOP AND SV.MASV = DIEM.MASV
          AND DIEM.MAMH = MH.MAMH
    END
    ```

    ```sql
    CREATE PROC SP_BDMH_XULYTOIUU
    @malop NVARCHAR(10), @mamh NVARCHAR(10),  @lan INT
    AS
    BEGIN
      DECLARE @TENLOP NVARCHAR(100), @TENMH NVARCHAR(100)
      SELECT @TENLOP= TENLOP FROM LOP WHERE MALOP = @malop
      SELECT @TENMH = TENMH FROM MONHOC WHERE MAMH = @mamh

      SELECT TENLOP=@TENLOP , TENMH=@TENMH  , SV.MASV ,
                    HOTEN=HO+' '+TEN, DIEM
            FROM  (SELECT MASV, HO,TEN FROM SINHVIEN WITH (INDEX=IX_MALOP) WHERE MALOP = @malop) SV,
               (SELECT MASV , DIEM FROM DIEM WHERE MAMH = @mamh AND LAN = @lan) DIEM
        WHERE   SV.MASV = DIEM.MASV
    END
    ```

3.  Nếu 1 điều kiện xuất hiện nhiều lần trong WHERE thì dùng các phép biến đổi tương đương để cho điều kiện đó xuất hiện 1 lần.
    ```
    P1 ^ ( P2 v P3)       ≡ ( P1 ^ P2) v (P1 ^ P3)
    P1 v ( P2 ^ P3)       ≡ ( P1 v P2) ^ (P1 v P3)
    P1 ^ ( P1 v P2 v P3)  ≡ P1
    P1 v ( P1 ^ P2 ^ P3)  ≡ P1
    ```

4.  Trong mệnh đề AND, điều kiện nào có xác suất sai cao thì đặt ở đầu; OR thì ngược lại.

5.  Field tham gia trong điều kiện truy vấn nên được sắp thứ tự trước, và thứ tự này phải được sử dụng trong mệnh đề truy vấn với `WITH (INDEX=ten_index)`