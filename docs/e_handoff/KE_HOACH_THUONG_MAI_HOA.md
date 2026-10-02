# TokenVector — Kế hoạch thương mại hóa

Cập nhật 2026-08-06. Tổng hợp từ tư vấn Gemini + hiệu chỉnh thực tế theo đúng
ràng buộc của người làm (1 laptop Pentium Silver 4GB RAM, 0 tiền mặt, mục
tiêu ban đầu 10 triệu VND/ngày). Đọc phần "Sự thật thẳng" TRƯỚC — đây là phần
Gemini né tránh khi được hỏi thẳng, chèn vào đây để không bị lạc quan ảo.

---

## 0. Sự thật thẳng — đọc trước khi làm gì khác

**10 triệu VND/ngày (~300 triệu/tháng) trong tuần/tháng đầu: KHÔNG khả thi.**
Không phải bi quan — đây là con số logic: TokenVector hiện có 0 người dùng,
0 thương hiệu, 0 kênh phân phối, cạnh tranh với Cython/Nuitka/PyPy/Codon —
những dự án 10+ năm tuổi, hàng nghìn contributor. Không ai trả 10tr/ngày cho
compiler chưa ai biết, dù nhanh hơn CPython 24 lần.

**Mốc doanh thu thực tế theo giai đoạn:**

| Giai đoạn | Doanh thu kỳ vọng | Vì sao |
|---|---|---|
| Ngày 1-30 | **0 đồng** | Mục tiêu là traction (GitHub stars, traffic), không phải tiền |
| Ngày 30-60 | 0 - vài trăm nghìn (GitHub Sponsors donate) | Cần ít nhất 1 bài đăng "nổi" trên HN/Reddit |
| Ngày 60-90 | 1-5 triệu **một lần** (không phải/ngày) | 1 hợp đồng tư vấn/port code 1 lần, nếu may mắn gặp đúng khách |
| Tháng 6-12 | Có thể tiệm cận vài triệu/ngày **trung bình** nếu có 3-5 khách Enterprise trả theo năm | Kịch bản LẠC QUAN, cần launch đều, không bỏ dở |
| Năm 2+ | 10tr/ngày ổn định khả thi nếu có ~10-15 khách Enterprise ($3-10k/năm) | Bán B2B kiểu này thường mất 1-2 năm ngay cả với sản phẩm tốt và đội ngũ đầy đủ |

**Mục tiêu 90 ngày đầu nên đặt lại**: không phải doanh thu, mà là **có 1
khách hàng trả tiền THẬT (dù chỉ 500k-2 triệu 1 lần)** — đó là bằng chứng mô
hình có thể hoạt động, giá trị hơn nhiều so với đuổi theo con số 10tr/ngày
ảo tưởng.

---

## 1. Định vị & lợi thế cạnh tranh (giữ nguyên từ Gemini, đã kiểm hợp lý)

| Đối thủ | Điểm yếu của họ | TokenVector khác gì |
|---|---|---|
| Cython/Numba | Phải viết lại code/dùng decorator, cần toolchain C/C++ phức tạp trên Windows | Python thuần, không sửa code |
| PyPy | JIT ngốn RAM, khó đóng gói standalone, interop .NET kém | Sinh `.exe` độc lập, chạy thẳng trên CLR |
| Mojo | Ngôn ngữ mới, phải học cú pháp mới | Cú pháp Python y hệt |
| **TokenVector** | — | `.exe`/`.dll` độc lập, không cần cài CPython; bảo vệ IP (không lộ source Python); interop .NET 2 chiều không qua IPC nặng |

**Khách hàng mục tiêu thực tế nhất** (xếp theo khả năng tiếp cận với 0 vốn):
1. **Cộng đồng Python Việt Nam** — dễ tiếp cận nhất qua Facebook group/Discord, không cần tiếng Anh, ít cạnh tranh nội dung tiếng Việt về chủ đề này.
2. **Dev cá nhân/freelancer cần đóng gói script Python thành `.exe` bảo vệ code** — nhu cầu có thật, tìm kiếm nhiều trên Google ("python to exe protect source code"), nhưng PyInstaller/Nuitka đã chiếm chỗ — phải có USP rõ ràng (nhanh hơn + không lộ source ở mức bytecode).
3. **ISV nhỏ cần .NET interop** (thị trường ngách hẹp, nhưng ít cạnh tranh) — khó tiếp cận qua kênh miễn phí, cần outbound.

## 2. Mô hình giá (giữ cấu trúc Gemini, điều chỉnh kỳ vọng)

| Gói | Đối tượng | Giá | Ghi chú thực tế |
|---|---|---|---|
| Community | Dev cá nhân, OSS | Miễn phí | Bắt buộc để có traction; đây là toàn bộ trọng tâm 90 ngày đầu |
| Pro | Dev/team nhỏ | $9-15/tháng (KHÔNG phải $29-49 như Gemini đề xuất — giá đó quá cao cho 1 sản phẩm chưa ai biết, không track record) | Chỉ launch SAU KHI có ≥50 người dùng Community thật |
| Enterprise | B2B, ISV | Thương lượng theo dự án, KHÔNG cố định $3-10k/năm ngay | Bán được 1 hợp đồng đầu tiên mới định giá theo thị trường, đừng tự đặt giá cao khi chưa có ai từng trả |

**Vì sao hạ giá Pro so với Gemini đề xuất**: $29-49/tháng là giá của sản
phẩm có track record (Cursor, JetBrains...). Một compiler 0 người dùng đòi
giá đó sẽ 0 người mua — mất cơ hội thu thập feedback + case study thật.

## 3. Lộ trình thực thi — điều chỉnh theo máy yếu + 0 vốn

Nguyên tắc: **mọi việc phải làm được trên Pentium Silver 4GB RAM, không cần
build .NET nặng lặp lại nhiều lần trong ngày.** Ưu tiên viết/quay video/đăng
bài (nhẹ máy) hơn là build liên tục.

### Tuần 1 — Checklist ngay (0 tiền, nhẹ máy)

- [ ] `README.md` chỉn chu: quickstart, bảng benchmark thật (đã đo: nhanh hơn
  CPython tới 24x ở một số case — dùng SỐ THẬT, không phóng đại), giới hạn rõ
  ràng (chưa hỗ trợ NumPy/SciPy/C-extension).
- [ ] 1 video demo ngắn (1-2 phút): quay màn hình biên dịch 1 script Python
  thật, so thời gian chạy `.exe` vs `python script.py`. Dùng phần mềm quay
  màn hình nhẹ (không cần GPU).
- [ ] Đăng case study CodeGraph: "Dùng TokenVector viết công cụ phân tích
  code thật — 15 công cụ, 9.400+ cạnh đồ thị, 132/132 test xanh" — đây là
  bằng chứng SẢN PHẨM THẬT, không phải benchmark ảo, là điểm mạnh nhất hiện
  có.
- [ ] Landing page đơn giản (GitHub Pages — miễn phí, không cần hosting trả
  phí): 1 value prop duy nhất + link GitHub + form thu email (dùng Google
  Form miễn phí, không cần dịch vụ trả phí).

### Tuần 2-4 — Launch cộng đồng (0 tiền)

- [ ] Đăng cộng đồng Python Việt Nam (Facebook groups, Discord) — ưu tiên vì
  ít cạnh tranh, không rào cản ngôn ngữ.
- [ ] Show HN + r/Python + r/csharp + r/dotnet — chuẩn bị tiêu đề rõ, ví dụ:
  "Show HN: TokenVector — Python-to-.NET IL compiler, up to 24x faster than
  CPython". Đăng vào giờ US traffic cao nếu nhắm HN quốc tế.
- [ ] 1 bài kỹ thuật deep-dive ("TokenVector map AST Python sang MSIL thế
  nào") đăng Dev.to/Medium — SEO dài hạn, không tốn tiền.

### Tháng 2-3 — Thu thập feedback, KHÔNG bán vội

- [ ] Theo dõi ai thực sự dùng thử, hỏi trực tiếp họ cần gì (không đoán).
- [ ] Nếu có ai hỏi "trả tiền được không" — đó là tín hiệu launch Pro sớm,
  đừng đợi đủ roadmap mới bán.
- [ ] KHÔNG build tính năng Enterprise (interop C# nâng cao, obfuscation)
  trước khi có ít nhất 1 khách hỏi cụ thể — tránh làm tính năng không ai cần.

### Tháng 4+ — Chỉ khi đã có traction thật

- [ ] Ra gói Pro ($9-15/tháng) nếu có ≥50 người dùng Community.
- [ ] Outbound tới 1-2 công ty nhỏ cụ thể (không rải đại trà) nếu có use
  case rõ ràng khớp với TokenVector.

## 4. Rủi ro (giữ từ Gemini + bổ sung)

- **Tương thích C-extension (NumPy/SciPy/PyTorch)**: không giải được ngắn
  hạn — định vị rõ "Pure Python logic, không phải data science stack".
- **Python ra bản mới liên tục**: rủi ro thấp hơn Gemini lo ngại vì
  TokenVector dùng cú pháp con (subset), không cần đuổi theo mọi tính năng
  mới ngay.
- **Làm một mình trên máy yếu → burnout**: rủi ro LỚN NHẤT thực tế, Gemini
  không đề cập đủ. Giải pháp: không đặt deadline doanh thu cứng, ưu tiên
  công việc nhẹ máy (viết/quay/đăng) hơn là build lặp lại liên tục.
- **Mục tiêu "ngang bằng Python hoàn toàn" là vô hạn**: đừng chờ "xong" mới
  thương mại hóa — sản phẩm hiện tại (132/132 test, CodeGraph dùng thật) đã
  đủ để launch Community edition ngay.
- **Cạnh tranh với dự án 10+ năm tuổi**: không thắng bằng feature parity,
  chỉ thắng bằng ngách hẹp (bảo vệ IP Python trên Windows/.NET, interop
  .NET) — đừng cố cạnh tranh toàn diện.

## 5. Việc làm NGAY hôm nay (không cần chờ gì thêm)

1. Viết `README.md` với số liệu benchmark thật đã có.
2. Đăng case study CodeGraph lên 1 nơi (Facebook Python VN hoặc Reddit).
3. Tạo Google Form thu email "muốn dùng thử".

Không làm gì khác trước 3 việc này — mọi tính năng/gói giá/outbound đều vô
nghĩa khi chưa có ai biết sản phẩm tồn tại.
