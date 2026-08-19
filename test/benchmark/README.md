# test/benchmark/ — ĐO HIỆU NĂNG, KHÔNG PHẢI TEST ĐÚNG/SAI

Tách khỏi `test/verify/` ngày 2026-08-03. Lý do:

1. **Không assert gì** — các file ở đây chỉ IN số liệu, không so với giá
   trị kỳ vọng, không `sys.exit(1)` khi số xấu. "Chạy xong" KHÔNG có
   nghĩa "hiệu năng đạt". Tính đúng đắn do `test/verify/` lo.
2. **Rất chậm** — `benchmark_goal4_footprint.py` mất ~2 phút 12 giây
   (riêng 10 lần chạy sklearn đã ~120 giây). Để trong `test/verify/` thì
   nó chiếm ~2/3 thời gian mỗi lần chạy regression và tạo ra "fail" GIẢ
   khi harness đặt timeout ngắn.

**Không đưa file ở đây vào lần chạy regression thường lệ.** Chạy tay khi
cần đo:

    python test/benchmark/benchmark_goal4_footprint.py

## Diễn giải số liệu cho đúng (bài học 2026-08-03)

Tỷ lệ "113,6x" của phần B là so **ở tầng triển khai** (khởi động nguội 1
tiến trình): kịch bản sklearn phải `import joblib/numpy/sklearn` +
`joblib.load()` 2 file `.pkl` + `load_iris()` MỖI LẦN CHẠY — phần lớn
thời gian đó là NẠP THƯ VIỆN, không phải tính toán. Đọc đúng là "thay cả
stack Python bằng 1 file .exe thì rẻ hơn 113 lần cho mỗi lần gọi nguội",
KHÔNG phải "IL nhanh hơn numpy 113 lần".

## Hạn chế phương pháp đã biết (chưa sửa)

- Vòng lặp đo RAM (`while proc.poll() is None`) KHÔNG có `sleep` → quay
  100% một lõi CPU trong lúc đo, cạnh tranh tài nguyên với chính tiến
  trình đang đo. Trên máy cấu hình thấp có thể làm lệch chính số đang đo.
- `sample_output` được thu nhưng KHÔNG đối chiếu giá trị kỳ vọng.

## KHI NÀO chạy benchmark (chính sách owner đặt 2026-08-03)

Hiệu năng **VẪN LÀ thước đo chính** để đánh giá TokenVector có tốt hơn
Python hay không — tách khỏi `test/verify/` KHÔNG có nghĩa hạ cấp nó,
chỉ là không chạy mỗi lần test.

**Chạy khi HOÀN THÀNH 1 ĐOẠN CÔNG VIỆC LỚN**, ví dụ:
- Xong trọn một Giai đoạn của kế hoạch parity (vd xong toàn bộ 0.2)
- Trước khi chốt/gộp một nhánh tính năng lớn
- Sau khi đụng vào lõi sinh mã (`il_codegen.py`/`il_core.py`) theo cách
  có thể ảnh hưởng mã sinh ra

**KHÔNG chạy**: mỗi lần regression thường lệ, mỗi lần sửa 1 module stdlib.

    python test/benchmark/benchmark_goal4_footprint.py

Ghi số đo + ngày vào `STATUS.md` để so được theo thời gian (số liệu chỉ
có giá trị khi có mốc trước để đối chiếu).
