# TokenVector

**Biên dịch Python thành 1 file `.exe` độc lập, chạy nhanh gấp ~8× CPython — không cần cài Python trên máy đích.**

TokenVector là trình biên dịch cho `.tkv` — một tập con Python có kiểu
tĩnh. File `.tkv` **vẫn là mã Python hợp lệ 100%**, chạy được thật dưới
CPython (dùng để đối chiếu kết quả, không phải cú pháp riêng phải học lại).
TokenVector biên dịch thẳng sang CIL (.NET IL) rồi lắp bằng `ilasm.exe`
(có sẵn trong .NET Framework trên mọi máy Windows) thành 1 `.exe` native —
không cần cài Python, không cần đóng gói interpreter nặng nề như PyInstaller.

```powershell
dist\tkvc.exe build examples\word_stats.tkv
examples\word_stats.exe "the quick brown fox the fox runs"
```

## Vì sao dùng TokenVector thay vì PyInstaller/Cython/Nuitka?

| | TokenVector | Python (đóng gói bằng PyInstaller) | Cython/Nuitka |
|---|---|---|---|
| Cú pháp | Python thuần (thêm chú thích kiểu) | Python thuần | Phải viết lại/thêm decorator |
| Toolchain đích | .NET Framework có sẵn trên Windows | Nhúng cả interpreter (15-40MB/file) | Cần C/C++ toolchain phức tạp |
| Bảo vệ mã nguồn | Biên dịch thẳng ra CIL, không đóng gói `.py` gốc | `.py`/`.pyc` vẫn nằm trong gói, dễ giải nén | Tùy cấu hình |
| Tốc độ chạy | **~8× nhanh hơn CPython** | Bằng CPython (chỉ đóng gói, không tối ưu) | Nhanh, nhưng cần viết lại code |

## Số liệu benchmark thật (đo trên máy phát triển, không phóng đại)

Đo chi tiết đầy đủ ở [`benchmark_phase_c/benchmark_toandien.md`](benchmark_phase_c/benchmark_toandien.md).
Tóm tắt:

| Chỉ số | TokenVector | Python3 | C# |
|---|---:|---:|---:|
| Tốc độ chạy (trung bình 4 bài, N=5 triệu vòng lặp) | 0.298s | 2.399s | 0.247s |
| So với Python | **nhanh hơn 8.0×** (cao nhất 9.2×) | — | nhanh hơn 9.7× |
| So với C# | chậm hơn ~21% | — | — |
| Khởi động (cold start) | 0.144s | 0.255s | 0.133s |
| File `.exe` (bài trung bình) | 2.560 bytes | không áp dụng | 4.224 bytes |
| Cài đặt cho người dùng cuối | chỉ 1 file `.exe` | cần Python 2.88GB hoặc PyInstaller 15-40MB/file | chỉ 1 file `.exe` |

→ TokenVector nhanh hơn Python rõ rệt, gần bằng C# thật (Roslyn), và nhẹ hơn
C# ~30-40% về kích thước file. Đổi lại, đây **không phải** ngôn ngữ tổng
quát — xem "Giới hạn thật" bên dưới trước khi dùng.

## Đã dùng để viết công cụ thật, không chỉ chạy benchmark

[CodeGraph](../CodeGraph/) — bộ phân tích code 15 công cụ (parser, đồ thị
lời gọi hàm, suy luận kiểu, phát hiện miền/domain, lần vết tác động thay
đổi...) **viết hoàn toàn bằng TokenVector**, biên dịch thật, chạy thật trên
dữ liệu thật: hiện phân tích 767 file, dựng **9.410+ cạnh đồ thị**, 15/15
test tự động xanh.

## Bắt đầu ngay

Xem [USAGE_GUIDE.md](USAGE_GUIDE.md) để biết cú pháp `.tkv` đầy đủ.

## Cấu trúc thư mục

- `dist/tkvc.exe` — công cụ biên dịch độc lập (đóng gói sẵn, không cần
  cài Python để dùng).
- `compiler/` — lõi biên dịch (Python; chỉ cần thiết để TỰ BUILD lại
  `tkvc.exe`, không cần cho người dùng cuối chạy `.tkv`).
- `examples/` — ứng dụng mẫu viết bằng TokenVector.
- `test/` — file `.tkv`/`.exe`/`.il` mẫu + `test/verify/` (bộ kiểm chứng
  nội bộ, 132/132 test xanh — chạy `python test/run_tests.py`).
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

TokenVector **không và không nên** cạnh tranh về độ rộng với Python/C# —
đây là compiler cá nhân nhắm vào 1 tập con cụ thể: tính toán số/logic
hiệu năng cao. Cụ thể:

- **Không hỗ trợ** thư viện C-extension (NumPy, SciPy, PyTorch...), web
  framework, GUI, database, đa luồng.
- Thư viện chuẩn chỉ là tập con nhỏ (string/regex/json/file I/O/toán học
  cơ bản), phải tự map từng hàm vào .NET BCL.
- Chưa có package manager/hệ sinh thái thư viện bên thứ 3.
- Dự án cá nhân — chưa có IDE support, debugger, cộng đồng hỗ trợ.

Xem đầy đủ mục "Giới hạn thật" trong [USAGE_GUIDE.md](USAGE_GUIDE.md) và
so sánh chi tiết ở [`benchmark_phase_c/benchmark_toandien.md`](benchmark_phase_c/benchmark_toandien.md).

## Lịch sử phát triển

`ROADMAP.md`/`STATUS.md` là nhật ký quá trình phát triển (lịch sử, có
thể thiếu tính năng hoàn tất gần đây) — KHÔNG phải tài liệu tham khảo
tính năng hiện tại, dùng USAGE_GUIDE.md cho việc đó.
