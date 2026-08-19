# TokenVector

Biên dịch một tập con Python có kiểu tĩnh (`.tkv` — vẫn là mã Python hợp
lệ 100%, chạy được thật dưới CPython) thẳng thành CIL rồi lắp ráp bằng
`ilasm.exe` (có sẵn trong .NET Framework) thành **1 file `.exe` độc lập**
— không cần Python hay bất kỳ runtime nào khác để chạy.

**Bắt đầu ngay**: xem [USAGE_GUIDE.md](USAGE_GUIDE.md).

```powershell
dist\tkvc.exe build examples\word_stats.tkv
examples\word_stats.exe "the quick brown fox the fox runs"
```

## Cấu trúc thư mục

- `dist/tkvc.exe` — công cụ biên dịch độc lập (đóng gói sẵn, không cần
  cài Python để dùng).
- `compiler/` — lõi biên dịch (Python; chỉ cần thiết để TỰ BUILD lại
  `tkvc.exe`, không cần cho người dùng cuối chạy `.tkv`).
- `examples/` — ứng dụng mẫu viết bằng TokenVector.
- `test/` — file `.tkv`/`.exe`/`.il` mẫu + `test/verify/` (bộ kiểm chứng
  nội bộ dùng Python, chỉ dành cho người phát triển TokenVector).
- `build_tkvc.ps1` — script tự build lại `tkvc.exe` sau khi sửa
  `compiler/*.py`.

## Công cụ phụ khác trong thư mục này

Ngoài compiler `.tkv` chung ở trên, thư mục còn 2 công cụ RIÊNG, hẹp hơn,
ra đời trước và không liên quan cú pháp `.tkv` chung:

- **`cli.py`/`tokenvector_compile.py`** — biên dịch 1
  `sklearn.neural_network.MLPClassifier` đã train sẵn (1 hidden layer)
  thành `.exe` độc lập, không cần Python/sklearn lúc chạy:
  ```bash
  python cli.py --model model.pkl --scaler scaler.pkl \
      --labels setosa,versicolor,virginica --out iris.exe
  iris.exe 6.1 2.9 4.7 1.4
  ```
  Giới hạn: chỉ 1 hidden layer, chỉ multi-class, scaler (nếu có) phải là
  `MinMaxScaler`.

- **`alphaai_codegen.py`** — khi kiến trúc mạng KHÔNG khớp khuôn mẫu trên
  (vd 2+ hidden layer), dùng AI (Groq) tự viết thân hàm `.tkv`, biên dịch
  thật + xác nhận qua `ilasm.exe` (không đoán mò, tự sửa lại nếu lỗi biên
  dịch, tối đa 3 lần).

## Giới hạn thật (không phóng đại)

Xem mục "Giới hạn thật" trong [USAGE_GUIDE.md](USAGE_GUIDE.md).

## Lịch sử phát triển

`ROADMAP.md`/`STATUS.md` là nhật ký quá trình phát triển (lịch sử, có
thể thiếu tính năng hoàn tất gần đây) — KHÔNG phải tài liệu tham khảo
tính năng hiện tại, dùng USAGE_GUIDE.md cho việc đó.
