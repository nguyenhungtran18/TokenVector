# Thiết kế: Tự-host hoá TokenVector Compiler (Mục tiêu 5)

Ngày: 2026-08-03. Quyết định chốt qua hội thoại brainstorm cùng owner (xem
memory `feedback-no-python-use-tokenvector-to-generate-code.md` và
`project-tokenvector-4-goals.md` mục 5 mới thêm).

## Bối cảnh & quan hệ với các mục tiêu khác

Mục tiêu 1 gốc ("thay Python", 2026-07-28) là góc nhìn NGƯỜI DÙNG CUỐI —
chương trình TokenVector chạy không cần cài Python. Mục tiêu này **đã đạt**
(212 file `.tkv`, 106 module stdlib, biên dịch ra `.exe` .NET độc lập).

Mục tiêu 5 (MỚI, hôm nay) khắt khe hơn: bản thân **công cụ biên dịch**
(`tkvc.exe`, hiện ~10,164 dòng Python trong `compiler/`) cũng không cần
Python để PHÁT TRIỂN TIẾP. Owner xác nhận: theo đuổi **song song**, KHÔNG
thay thế Giai đoạn 0 (kế hoạch v2 sửa `il_core.py`/`il_codegen.py` bằng
Python vẫn tiếp tục làm ngay, xem `~/.claude/plans/tokenvector-close-python-gap-2026-08-02.md`).

## Bootstrap (đã chốt, không còn mở)

Nghịch lý con-gà-quả-trứng: không có compiler nào khác ngoài `tkvc.exe`
(Python) để biên dịch `.tkv`. Giải pháp đã chốt:

1. Dùng `tkvc.exe` **hiện có, KHÔNG sửa thêm 1 dòng Python nào**, làm
   bước biên dịch DUY NHẤT — biên dịch `compiler_v1.tkv` (bộ file viết
   bằng chính TokenVector, xem kiến trúc bên dưới) → `tkvc_v2.exe`.
   (DÙNG tool có sẵn không phải VIẾT Python mới — giống dùng `gcc` để
   biên dịch code C không có nghĩa đang "lập trình C".)
2. Từ `tkvc_v2.exe` trở đi, mọi phát triển compiler tiếp theo viết bằng
   TokenVector, biên dịch bằng chính `tkvc_v2.exe` (rồi v3, v4...).
   Không quay lại sửa `.py` cho nhánh này nữa.

## Phạm vi MVP (compiler_v1) — điều kiện "đã tự-host thật"

Tiêu chí thành công: `tkvc_v2.exe` tự biên dịch lại được **chính mã
nguồn `compiler_v1.tkv`** (ra `tkvc_v3.exe` hoạt động y hệt) + biên dịch
đúng vài chương trình mẫu (`hello.tkv`, tính Fibonacci đệ quy). Không
cần hỗ trợ ngay 28+ tính năng stdlib hiện có của compiler Python — chỉ
cần đủ tập lõi mà CHÍNH compiler_v1 dùng để viết bản thân nó (giống
compiler C đời đầu chỉ cần hỗ trợ đúng tập con C mà chúng tự viết bằng).

**Tập cú pháp lõi cần**: biến+gán, `if/elif/else`, `while`, `for`, hàm
(định nghĩa+gọi+đệ quy), số học/so sánh, `str` (index/slice/nối —
lexer.tkv mẫu đã dùng), `list` qua `.append()` (KHÔNG cần list-literal
`[1,2,3]` — né đúng gap Giai đoạn 0 bằng cách viết vòng lặp+append như
`lexer.tkv` hiện có đang làm), `dict` cơ bản (bảng token/symbol table).

**KHÔNG cần cho v1** (để lại v2, sau khi đã tự-host): closures,
generator, exception, list-literal cú pháp, builtin-compose-trong-biểu-thức,
28+ module stdlib khác — compiler_v1 chỉ cần TỰ ĐỦ, không cần TOÀN DIỆN.

## Kiến trúc file

Mirror ranh giới module của `compiler/*.py` hiện tại nhưng thu hẹp phạm
vi, đặt trong `compiler_src/` (đã có sẵn 3 file stub, mở rộng tiếp):

- **`lexer.tkv`** (mở rộng bản có sẵn 72 dòng, chỉ tokenize 1 dòng): thêm
  tokenize TOÀN FILE + tracking INDENT/DEDENT (phần khó nhất — PORT logic
  thật từ `_tokenize_expr`/xử lý thụt đầu dòng trong `il_core.py` hiện
  có, KHÔNG tự sáng tác lại tay, đúng nguyên tắc "port cái có sẵn" của
  dự án).
- **`ast_types.tkv`** (MỚI): định nghĩa AST node bằng `record` đã có sẵn
  trong TokenVector (KHÔNG cần tính năng Giai đoạn 0). RỦI RO CHƯA XÁC
  MINH: record có hỗ trợ field tham chiếu ĐỆ QUY tới record cùng kiểu
  hoặc kiểu khác (cây AST) hay không — bắt buộc spike xác minh TRƯỚC khi
  viết parser đầy đủ (xem "Rủi ro" bên dưới).
- **`symtable.tkv`** (MỚI): scope/symbol table dùng `dict` đã có sẵn.
- **`parser.tkv`** (MỚI): parser đệ quy giảm dần (recursive-descent),
  vào = token list từ lexer, ra = AST record. Phụ thuộc `ast_types.tkv`
  qua INTERFACE (kiểu record) đã chốt trước, không cần chờ lexer 100%
  xong để bắt đầu viết.
- **`codegen_cil.tkv`** (mở rộng bản có sẵn 19 dòng): sinh text CIL cho
  từng loại AST node — port logic từ `il_codegen.py`'s `EXPR_CODEGEN`/
  `STMT_CODEGEN` (KHÔNG thiết kế lại từ đầu).
- **`tkvc_main.tkv`** (mở rộng bản có sẵn 14 dòng): đọc file nguồn →
  lexer → parser → codegen → ghi `.il`. KHÔNG tự gọi `ilasm.exe` trong
  v1 (tránh phụ thuộc tính năng gọi process ngoài chưa xác nhận có sẵn)
  — bước `.il` → `.exe` vẫn gọi `ilasm.exe` từ ngoài (script/agent),
  giống quy trình build hiện tại của chính `tkvc.exe`.

## Kiểm thử & xác minh (bắt buộc — "verify nghĩa là verify")

1. **Đối chiếu song song**: mỗi file `.tkv` nhỏ trong bộ lõi, chạy CẢ
   `tkvc.exe` (Python, nguồn sự thật) VÀ `tkvc_v2.exe` (tự-host) — diff
   `.il` sinh ra / hành vi runtime, PHẢI khớp. "Biên dịch không lỗi"
   KHÔNG được chấp nhận là bằng chứng đủ (bài học cũ: false-green
   `run_stdlib_tests.py`, xem memory `project-tokenvector-python-parity-gaps`).
2. **Test tự-biên-dịch** (điều kiện thắng thật): `tkvc_v2.exe` biên dịch
   lại CHÍNH `compiler_v1.tkv` (toàn bộ file trong `compiler_src/`) ra
   `tkvc_v3.exe`, và `tkvc_v3.exe` phải hoạt động giống hệt `tkvc_v2.exe`
   trên cùng bộ test — đây mới là "đã tự-host", không phải chỉ "biên
   dịch được chương trình người dùng".

## Rủi ro lớn nhất (ghi trung thực, không né tránh)

- **Record đệ quy chưa xác minh**: nếu TokenVector KHÔNG hỗ trợ record
  tham chiếu tới record khác trong 1 field (cần cho cây AST), phải đổi
  thiết kế sang biểu diễn mảng song song (parallel arrays, kiểu
  "struct-of-arrays") — phức tạp hơn nhiều, cần quyết định lại kiến
  trúc từ đầu. BẮT BUỘC spike xác minh đây là việc làm ĐẦU TIÊN.
- **INDENT/DEDENT tracking**: phần dễ sai nhất khi viết lại tay, phải
  port đúng logic Python hiện có, không suy diễn.
- **Quy mô thật (đã hiệu chỉnh 2026-08-03, sau phản biện của owner)**:
  ước lượng ban đầu "hàng tuần/tháng" bị BÁC BỎ ĐÚNG — đó là suy diễn
  kiểu 1-người-gõ-tay, không tính 2 yếu tố thật của chính dự án: (a) đây
  là PORT logic Python ĐÃ ĐÚNG/ĐÃ TEST sang cú pháp TokenVector, không
  phải thiết kế thuật toán mới — rủi ro thấp hơn nhiều so với code mới;
  (b) tốc độ nhiều AI agent song song đã CHỨNG MINH THẬT: TokenVector đạt
  9/9 roadmap + tính năng hậu-roadmap (dict/closures/generator/exception/
  record...) chỉ trong ~6 ngày (2026-07-28→2026-08-03, xem memory
  `project-tokenvector-4-goals`). Ước lượng lại: phần LÕI tự-host (Giai
  đoạn A-C, lexer+parser+codegen tối thiểu để tự biên dịch) khả thi
  trong **vài ngày** làm việc tập trung với agent song song, không phải
  tuần/tháng, MIỄN LÀ spike record-đệ-quy (rủi ro đầu tiên ở trên) không
  vỡ thiết kế. Port đầy đủ 55 module `il_features/*.py` sau khi lõi ổn
  định cũng mang tính cơ giới/song song hoá được tương tự, quy mô lớn
  hơn nhưng KHÔNG có lý do để giả định chậm hơn phần lõi theo tỷ lệ
  tuyến tính đơn giản.

## Điều phối đa-agent (theo đúng "phân rã tác vụ" của CLAUDE.md)

- **Giai đoạn A** (1 agent, làm trước, ngắn): spike xác minh record đệ
  quy; port logic indent-tracking từ Python sang thiết kế token stream
  cho `compiler_v1`; CHỐT interface (shape của token, shape của AST
  record) trước khi cho phép làm song song.
- **Giai đoạn B** (song song, 3 agent độc lập theo interface đã chốt ở
  A): Agent-Lexer (hoàn thiện `lexer.tkv` toàn file+indent), Agent-AST
  (`ast_types.tkv` + `symtable.tkv`), Agent-Codegen (`codegen_cil.tkv`
  cho từng loại node, test độc lập bằng AST viết tay thủ công — không
  cần chờ parser xong).
- **Giai đoạn C** (1 agent, sau khi B ổn định): `parser.tkv` nối
  lexer→AST, `tkvc_main.tkv` nối toàn bộ pipeline.
- **Giai đoạn D**: chạy 2 bộ test ở mục "Kiểm thử" — không coi là xong
  nếu chưa qua CẢ HAI.

## Ngoài phạm vi (không làm ở mục tiêu 5, giai đoạn này)

- Không port 28+ module `il_features/*.py` (functools/csv/json/http/...)
  sang self-host — các module này VẪN chạy được nhờ `tkvc.exe` cũ trong
  lúc chờ compiler_v1 trưởng thành; chỉ port khi compiler_v1 đã tự-host
  ổn định (mục tiêu 5 giai đoạn 2, chưa lên kế hoạch chi tiết).
- Không thay đổi/dừng Giai đoạn 0 (kế hoạch v2 sửa `.py`) — 2 nhánh chạy
  ĐỘC LẬP, không nhánh nào chặn nhánh kia.
