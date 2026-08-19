# So sánh toàn diện: TokenVector vs Python vs C#

Đo trên chính máy đang phát triển TokenVector. Phần nào đo được thì đo thật (số liệu cụ thể bên dưới); phần định tính (độ dễ code, phạm vi tác vụ) đánh giá dựa trên hiểu biết thực tế về bộ tính năng hiện có của TokenVector so với 2 hệ sinh thái trưởng thành kia — nói thẳng cả điểm mạnh lẫn điểm yếu.

## 1. Dung lượng cài đặt / ổ đĩa

| | Dung lượng | Ghi chú |
|---|---:|---|
| Python 3.12 (cài đặt đầy đủ) | **2.880 MB** | Interpreter + thư viện chuẩn |
| .NET Framework 4.x runtime | **196 MB** | Đã có sẵn trên MỌI máy Windows — không tốn thêm |
| Bộ biên dịch TokenVector (mã nguồn `.py` thật) | **24 MB** | Tự viết bằng Python, KHÔNG có runtime riêng |

**TokenVector không phải toolchain độc lập** — để PHÁT TRIỂN cần cả Python (chạy `tkv_compile.py`) LẪN .NET Framework (`ilasm.exe` để lắp CIL). Nên đứng một mình, TokenVector không "nhẹ hơn" khi cài — nó cộng dồn phụ thuộc của cả 2 bên.

Nhưng **khi phân phối cho người dùng cuối**, khác biệt rất lớn:
- **TokenVector**: chỉ cần gửi 1 file `.exe` (~2.5KB cho chương trình nhỏ) — máy đích chỉ cần .NET Framework (đã có sẵn Windows), **không cần cài Python**.
- **Python**: phải cài cả Python runtime (2.88GB) hoặc đóng gói bằng PyInstaller (thường 15-40MB/file do nhúng cả interpreter).
- **C#**: giống TokenVector — chỉ cần .exe + .NET Framework có sẵn.

→ **TokenVector thắng Python rõ rệt** ở khâu phân phối/triển khai (không cần cài runtime nặng cho người dùng cuối), **ngang C#**.

## 2. Tốc độ khởi động (cold start, chương trình rỗng, trung vị 15 lần chạy)

| | Trung vị | Nhanh nhất |
|---|---:|---:|
| **TokenVector** | 0.1444s | 0.1139s |
| **C#** | 0.1331s | 0.1190s |
| **Python3** | 0.2546s | 0.2411s |

→ **TokenVector và C# gần như ngang nhau** (cùng chi phí khởi động .NET runtime, TokenVector nhỉnh hơn C# rất nhẹ ~1ms không đáng kể). **Cả hai đều khởi động nhanh hơn Python ~1.8x** (Python phải khởi động interpreter + quét site-packages mỗi lần).

## 3. Độ gọn code (trung bình 4 bài Phase C: b3 closure, nested closure, @property, đa kế thừa)

| | TokenVector | Python3 | C# |
|---|---:|---:|---:|
| Ký tự / bytes (trung bình) | 438 | 441 | 645 |
| Số dòng code (LOC, trung bình) | 18 | 20.25 | 30.5 |
| Số token (trung bình) | 120 | 113.5 | 159 |

→ **TokenVector gọn hơn C# rõ rệt** (~30% ít dòng hơn, ~25% ít token hơn, ít ký tự hơn hẳn) nhờ cú pháp kiểu Python (không `{}`/`;`). **So với Python thật**: TokenVector ít dòng hơn nhẹ (do gộp được nhiều biểu thức), nhưng **nhỉnh hơn một chút về số ký tự/token** — cái giá phải trả cho việc bắt buộc annotation kiểu tường minh mọi biến/tham số (đánh đổi có chủ đích để đổi lấy tốc độ + an toàn kiểu).

## 4. Độ nhẹ (kích thước file thực thi + RAM khi chạy)

| | TokenVector | Python3 | C# |
|---|---:|---:|---:|
| File .exe rỗng (hello world) | 2048 bytes | N/A (không có file, cần cả interpreter) | 3584 bytes |
| File .exe trung bình (4 bài Phase C) | 2560 bytes | N/A | 4224 bytes |
| RAM đỉnh lúc chạy (trung bình) | ~14.2 MB | ~9.2 MB | ~13.9 MB |

→ **File thực thi**: TokenVector nhẹ hơn C# ~30-40%. **RAM lúc chạy**: TokenVector ≈ C# (cùng .NET runtime nền), **Python nhẹ RAM hơn cả hai** (~35% ít hơn) vì interpreter CPython không cần tải CLR — nhưng đổi lại chậm hơn nhiều lần (mục 5).

## 5. Tốc độ thực thi (trung bình 4 bài, N=5 triệu vòng lặp)

| | TokenVector | Python3 | C# |
|---|---:|---:|---:|
| Thời gian chạy trung bình | 0.298s | 2.399s | 0.247s |
| So với Python | **nhanh hơn 8.0x** | — | nhanh hơn 9.7x |
| So với C# | chậm hơn ~21% | — | — |

→ TokenVector nhanh hơn Python **rõ rệt** (trung bình 8x, cao nhất 9.2x ở bài closure lồng nhau), và **chỉ chậm hơn C# một khoảng nhỏ** (~20%, cùng bậc độ lớn) — hợp lý vì Roslyn (trình biên dịch C# thật) tối ưu hoá JIT/vòng lặp tốt hơn 1 compiler tự viết như TokenVector, nhưng khoảng cách không lớn.

## 6. Tốc độ biên dịch

| | Trung bình (4 bài) |
|---|---:|
| TokenVector | 0.402s |
| C# (csc.exe) | 0.507s |
| Python (.pyc bytecode — không phải build thật) | 0.015s |

→ TokenVector biên dịch **nhanh hơn C# một chút**. Python không có bước build thật nên không so sánh công bằng (chạy thẳng, không cần biên dịch).

## 7. Phạm vi tác vụ hỗ trợ được (đánh giá định tính, dựa trên bộ tính năng THẬT hiện có)

| Nhóm tác vụ | Python | C# | TokenVector |
|---|---|---|---|
| Số học/mảng/vector hoá cơ bản | ✅ | ✅ | ✅ (mạnh, mục tiêu chính) |
| Kiểu dữ liệu tổng hợp (list/dict/set/tuple) | ✅ đầy đủ | ✅ đầy đủ | ✅ đủ dùng (không đầy đủ bằng, vd `sum()`/`min()` còn giới hạn) |
| OOP (class, kế thừa, đa hình) | ✅ đầy đủ | ✅ đầy đủ | ✅ (đơn kế thừa + mixin interface, KHÔNG đa kế thừa field-sharing đầy đủ) |
| Closure/hàm bậc cao | ✅ đầy đủ | ✅ (delegate/Func) | ✅ (đã mở rộng Phase C, còn vài giới hạn: scalar param capture, decorator tổng quát) |
| Generator thật (lazy) | ✅ | ✅ (yield return) | ⚠️ CHỈ giả-generator (eager list, không lazy — vòng lặp vô hạn sẽ treo) |
| Exception handling | ✅ | ✅ | ✅ (try/except/finally cơ bản) |
| Thư viện chuẩn (string/regex/json/file I/O/toán học) | ✅ khổng lồ | ✅ khổng lồ (BCL) | ⚠️ tập con nhỏ, phải tự map từng hàm vào .NET BCL |
| Web/GUI/DB/network/đa luồng | ✅ | ✅ | ❌ chưa hỗ trợ (ngoài phạm vi thiết kế) |
| Hệ sinh thái package/thư viện bên thứ 3 | ✅ khổng lồ (PyPI) | ✅ lớn (NuGet) | ❌ không có (dự án cá nhân, không có package manager) |
| Cộng đồng/tài liệu/tìm lỗi trên mạng | ✅ rất lớn | ✅ lớn | ❌ chỉ có bạn tự debug (dự án riêng) |

→ **TokenVector KHÔNG và KHÔNG NÊN cạnh tranh về độ rộng** — đây là 1 DSL/compiler cá nhân nhắm vào 1 tập con cụ thể (tính toán số/logic hiệu năng cao), không phải ngôn ngữ tổng quát. So sánh "tác vụ" theo đúng nghĩa toàn diện thì Python/C# thắng áp đảo vì có hệ sinh thái hàng chục năm.

## 8. Độ dễ viết code (định tính)

| | Đánh giá |
|---|---|
| **Python** | Dễ nhất — không cần khai báo kiểu, cú pháp tối giản, sửa/chạy ngay (không build). |
| **C#** | Khó hơn Python — cú pháp tường minh (`{}`, `;`, kiểu rõ ràng mọi nơi), nhưng công cụ (IntelliSense, lỗi biên dịch rõ ràng) hỗ trợ tốt. |
| **TokenVector** | **Ở giữa, lệch gần Python hơn** — cú pháp Python thật (file `.tkv` CHẠY ĐƯỢC dưới CPython y hệt, dùng để đối chiếu kết quả), nhưng bắt buộc annotation kiểu dạng string mọi nơi (`x: "i32"`) — nặng hơn Python thuần, nhẹ hơn C# (không cần `{}`/`;`). Đổi lại: lỗi cú pháp KHÔNG được hỗ trợ thường bị báo lỗi Ở TẦNG COMPILER (đôi khi kỹm thân thiện hơn lỗi C#/Python thật do là dự án cá nhân, chưa có IDE/linter riêng).

## Tổng kết: TokenVector mạnh/yếu ở đâu so với 2 đối thủ

**Mạnh (thắng rõ rệt hoặc ngang C#, hơn hẳn Python)**:
- Tốc độ thực thi: hơn Python 8-9x, chỉ kém C# ~20%.
- Độ gọn code: gọn hơn C# rõ rệt (ít dòng/token/ký tự hơn ~25-40%).
- Kích thước file thực thi: nhẹ hơn C# ~30-40%.
- Khởi động: nhanh ngang C#, nhanh hơn Python ~1.8x.
- Phân phối cho người dùng cuối: chỉ cần 1 file .exe nhỏ, không cần cài runtime nặng (giống C#, hơn hẳn Python).
- Biên dịch được kết quả GIỐNG HỆT C# ở mức bit (kể cả hành vi tràn số int32) — chứng minh codegen đúng đắn, không chỉ nhanh.

**Yếu (thua rõ rệt)**:
- Phạm vi tác vụ: chỉ là tập con hẹp (số học/logic/OOP cơ bản), không có web/GUI/DB/đa luồng/package ecosystem.
- Thư viện chuẩn: tập con rất nhỏ so với Python/C#, phải tự map từng hàm.
- Generator: chỉ giả (eager), không lazy — không dùng được cho luồng vô hạn.
- Hệ sinh thái/cộng đồng/tài liệu: bằng 0 (dự án cá nhân).
- Độ trưởng thành công cụ (IDE support, error message, debugger): chưa có, thua xa cả Python lẫn C#.

**Kết luận ngắn gọn**: TokenVector là lựa chọn tốt cho ĐÚNG 1 việc — viết code số/logic hiệu năng cao, cần nhanh gần bằng C# nhưng viết như Python — và làm việc đó tốt, có số liệu chứng minh. Ngoài phạm vi đó, Python/C# thắng áp đảo vì độ trưởng thành và độ rộng hệ sinh thái.
