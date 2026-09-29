# SESSION HANDOFF — TokenVector compiler

Ngày: 2026-09-29. Trạng thái: **cổng 78/78 xanh, hai repo sạch**, không có việc
dở dang. Phiên này làm 7 feature liên tiếp, mỗi cái một commit, mỗi commit
kèm test và hai repo đều đã mirror.

---

## 1. Việc đã xong trong phiên này

| # | Feature | `3.code` | parent | Test |
|---|---|---|---|---|
| 0 | Timeout mỗi test trong gate | `fb73f8b` | `744e65e` | — |
| 1 | `raise <biến>` | `7863ee3` | `9252840` | `raise_var_test.tkv` 7/7 |
| 2 | `try/except/else` | `2d3e9dc` | `917917f` | `try_except_else_test.tkv` 10/10 |
| 3 | `for`/`while` `else` | `19a8a52` | `407eb5c` | `for_while_else_test.tkv` 15/15 |
| 4 | Comprehension nhiều `for` / `if` | `ba5f5d0` | `9b4c2df` | `comprehension_multi_for_test.tkv` 17/17 |
| 5 | Slice có bước `a[i:j:k]` | `d81bc4f` | `7d4ca62` | `slice_step_test.tkv` 16/16 |
| 6 | Set literal `s = {1,2,3}` | `bfdcfc7` | `fb5997d` | `set_literal_test.tkv` 13/13 |
| 7 | Duyệt set `for v in s:` | `268e050` | `19d0f52` | `set_iteration_test.tkv` 11/11 |

Kèm một commit dọn dẹp ở parent: `9448b74` (`preview.png` + `2.UI/media_player.html`).

**Quy tắc commit:** mỗi thay đổi commit vào **cả hai** repo. Commit của parent
ghi rõ `(mirrors 3.code <hash>)`. Luôn chạy gate trước khi commit.

---

## 2. Quy trình bắt buộc

```powershell
cd D:\TokenVector\3.code
.\build_tkvc.ps1                                   # REBUILD TRƯỚC KHI CHẠY GATE
.\tools\testkit_gate.ps1                          # cổng, timeout 120s/test
```

Sau **mỗi** thay đổi compiler phải clean build. Binary cũ che giấu hồi quy.

- Cổng: `Testkit/*_test.tkv`, entry `run` (không phải `main`).
- `native_test_suite.tkv` **không** thuộc cổng và vẫn không build vì thiếu
  `yield from`. Đừng dùng nó làm cổng.
- Kết quả mong đợi: `PASS=78  BUILDFAIL=0  TESTFAIL=0  OTHER=0 TIMEOUT=0`.

**Đối chiếu với CPython 3.11 trước khi viết kỳ vọng vào test.** Trong phiên này
tôi đoán sai 4 lần (`m1`, `m2`, `n2`, và kỳ vọng `a[::2]` trên `[0,1,2]`) — cả
bốn lần code đều đúng và CPython mới là chuẩn xác nhận. Chạy Python trước, viết
kỳ vọng sau.

---

## 3. Việc nên làm tiếp

### Ưu tiên 1 — Field container trên record (đang SAI, im lặng, chạy sai)

**Cẩn thận: ghi chú dưới đây thay cho chẩn đoán cũ.** Phiên sau đã từng ghi rằng
đây là "`container_arg_hints` không được nạp cho vị trí gọi constructor". **Chẩn
đoán đó sai** — đã thử sửa theo hướng đó, xong hoàn tác.

Sự thật: **record không hỗ trợ field kiểu container**, và đó là giới hạn của thiết
kế, không phải thiếu một dòng. Tham số `.ctor` của record lấy từ **field đã khai
báo** (dòng ~2892 `il_codegen.tkv` lọc bỏ field container khỏi danh sách tham số),
và `__init__` thật bị bỏ qua lúc biên dịch (dòng ~5568). Nên:

```
class C:
    items: "list[i32]"
    def __init__(self) -> "i32":
        self.items = [1, 2, 3]     # BIEN DICH OK, len(c.items) == 0
        return 0
```

Ba kiểu hỏng, **không cái nào báo lỗi lúc biên dịch**:

| Viết | Kết quả |
|---|---|
| `self.items = [1,2,3]` trong `__init__` | `len(c.items) == 0` — gán không có tác dụng |
| `c.items[0]` sau đó | `OverflowException` lúc chạy |
| `def __init__(self, s: "set[i64]")` rồi `C(t)` | `OverflowException` lúc chạy; call site phát `TkvInt::ToI32` trên **chính con set** |

Lưu ý: `class C: n: "i32"` + `def __init__(self)` **không** khai báo tham số thì báo
lỗi rõ ràng ngay ("record 'C' can 1 tham so (n), gap 0"). Cơ chế kiểm số tham số có
sẵn, chỉ là không bắt được trường hợp container.

Việc nên làm: **từ chối field container trên record bằng lỗi biên dịch rõ ràng**,
kèm cách dùng thay thế. Đã kiểm: **không file `.tkv` nào trong repo** khai field
container trong class, nên chặn không phá gì. Việc cần làm trước khi chặn: tìm chỗ
gom field của class body (chưa tìm ra — `records[name]` dựng ở đâu chưa rõ) và kiểm
đường compiler tự-host.

Cách dùng thay thế cho tới khi có: truyền container **sau** khi khởi tạo
(`c = C()` rồi `c.items = [1,2,3]` — cần kiểm lại xem có dính lỗi trên không), hoặc
dùng hàm thuần thay vì record.

### Ưu tiên 2 — `yield from`

Không kiểm chứng được bằng bộ suite nào chặn: `native_test_suite.tkv` là bộ 16
case duy nhất dùng nó, và file đó không build. Nên hoặc làm **kèm** một test
Testkit riêng, hoặc chấp nhận làm mù rồi tự viết test. Cần mở rộng state machine
generator (MoveNext/Current vào cùng đường yield) — khó hơn hẳn mọi thứ trong
phiên này.

### Còn lại trong known gaps

`conditional expressions` (`a if c else b` **và** `c ? a : b` — cả hai đều hỏng,
dù thông báo lỗi còn bảo dùng cú pháp thứ hai) · `del` · keyword-only và
positional-only · nested/tuple literal · dict literal `{"a": 1}` · `f(*xs)`/`f(**kw)`
(calls có arity tĩnh, không có `params[]`) · `@classmethod` (cố ý từ chối: runtime
chưa có `cls`).

---

## 4. Bẫy đã mắc — đọc trước khi sửa gì

Tất cả đều **trông như lỗi khác**, và nhiều cái làm hỏng hàng loạt chứ không
phải một test.

| Vấn đề | Hệ quả | Nơi |
|---|---|---|
| `ast.Num` đã bị **xoá** từ Python 3.12 (máy này 3.14) | Giết **cả pre-flight linter** bằng `AttributeError`; `tkvc.exe` in traceback trông chẳng giống lỗi cú pháp. Dùng `ast.Constant` | `syntax_baseline.tkv` |
| `sig.params` là list **Param object**, không phải tuple | Unpack → `TypeError`, cổng rơi về **0/77** — mọi file cùng lúc | `il_codegen.tkv` |
| `infer_scope` là `_DtypeOnlyScope` | Có `__getitem__` và `._d`, **không có** `.get()` | `il_codegen.tkv` |
| `Set-Content -Encoding utf8` của PS 5.1 | Ghi BOM, file hỏng. Dùng `-Encoding ascii` cho file test | PowerShell |
| `& $exe` không bao giờ quay lại nếu tiến trình treo | Kéo treo cả cổng. Dùng `Start-Process` + `WaitForExit(ms)` | mọi probe |
| `Start-Process -PassThru` không trả `ExitCode` nếu chưa đọc `.Handle` | **Mọi** test đọc `NULL`, cổng báo 0/71 với `EXIT` trên tất cả | probe script |
| Biểu thức nhiều dòng trong `.tkv` | `khong parse duoc factor tai OP ')'` — parser là line-based | test files |
| Annotate local (`fails: "i32" = 0`) | Bị từ chối; local suy kiểu tự động | test files |
| `__init__` phải khớp **đúng** field đã khai báo | `MissingMethodException` lúc chạy | records |
| `.Message` / `.InnerException` không phải field của record | Truy cập thuộc tính chỉ mở field khai báo | test files |
| `len(<biểu thức>)` không suy được hình dạng | `len({1,2,3})` hỏng — đây là lý do set literal inline chưa hỗ trợ | `il_codegen.tkv` |
| `in` chỉ nhận **biến đơn** | `x in {1,2,3}` hỏng | `il_codegen.tkv` |
| Sửa theo chẩn đoán **chưa kiểm** thì phải hoàn tác được | Phiên này đã sửa `_container_arg_hints` theo một chẩn đoán sai, rồi revert. Mất công nhưng `git checkout` gọn. **Đừng commit thứ vừa hoàn tác.** | — |

Hai cái bẫy về **ngữ nghĩa** dễ sai nhất:

- `else` của `try` bị bỏ qua khi handler bắt lỗi; `else` của `for` bị bỏ qua khi
  gặp `break`. **Cùng tên, điều kiện ngược chiều.** `continue` không bỏ qua
  `else` của vòng lặp; `break` trong vòng trong chỉ bỏ qua `else` của vòng trong.
- Dict gán nhiều lần thì **lần sau cùng thắng**. Tôi đoán "lần đầu thắng" và
  viết sai kỳ vọng.

---

## 5. Ghi chú thiết kế đáng nhớ

**Nhãn thay cho cờ.** `PLAN.md` Bước 4 vẽ sẵn dùng cờ `did_break` cho
`for/else`. Đó là **sai**: cờ cần một local mới mà tên phải duy nhất giữa hai lần
duyệt câu lệnh, mà hai bộ đếm đó không bảo đảm khớp. Dùng nhãn thì `codegen_break`
không đổi một dòng nào. Chi tiết ở `PLAN.md` Bước 4.

**`try/else` cũng vậy.** Lần đầu tôi lồng `.try` và phát nhãn sai chỗ → vòng lặp
vô hạn, đã revert. Ràng buộc CIL ép bố cục: `br` **không** được thoát khỏi thân
`.try` (ECMA-335 III.3.64), bắt buộc `leave`, nên nhãn "không có lỗi" bắt buộc
nằm ngoài vùng protected — đặt vào trong chính là chỗ gây lặp. Chi tiết ở
`PLAN.md` Bước 3.

**`PLAN.md` từng sai.** Nó xếp *dict comprehension* vào mục "cần thiết kế" trong
khi macro **đã có sẵn và chạy đúng** từ trước phiên này; thứ thật sự chặn nó là
pre-flight linter với giới hạn "chỉ 1 generator". Tài liệu bỏ sót một tính
năng **đã chạy** nguy hiểm hơn tài liệu nói "chưa làm". Đã sửa, và test mới khoá
lại các dạng vốn đã chạy để không ai "sửa" nó về hỏng.

**Đừng ship code không tới đường.** Tôi viết `EXPR_CODEGEN` cho set literal inline
rồi gỡ bỏ: mọi đường tiêu thụ đều bị chặn bởi hạn chế có sẵn, nên không test
được. Code không tới đường là nợ.

---

## 6. Cấu trúc repo

- `D:\TokenVector` — repo cha, có `origin`. Commit khéo mọi thứ.
- `D:\TokenVector\3.code` — nested repo, **không có remote**, nhưng commit được
  mirror sang cha. Tag `nested-3code-snapshot` → `9dfaaab` giữ 7 commit cũ.
  Hai repo cùng nhìn một file vật lý, nên `git checkout` bên trong làm **stat
  cache** của bên ngoài cũ. Nếu `git status` bên ngoài hiện `M` trong khi
  `git diff` rỗng, đó là stat cache — `git add` sẽ xác nhận nội dung giống
  nhau và xoá cờ.
- `D:\TokenVector\3.code\dist\tkvc.exe` — compiler, **phải rebuild**.
- `D:\TokenVector\3.code\tools\testkit_gate.ps1` — cổng, có timeout 120s.
- `D:\TokenVector\3.code\Testkit\tkv_test_lib.tkv` — `check()` và `test_summary()`.
  **Hàm con trả `total` (số check pass), chỉ `run()` gọi `test_summary`** — quy ước
  này tôi làm sai một lần, in ra `0/7` dù 7/7 đều PASS.

### Thư mục bẩn, đừng đụng

`tokenvector-grammar` là submodule có remote riêng. Working tree của nó bẩn:
xoá `tokenvector-syntax-1.0.0.vsix` (**file đã được track**) cộng ~15 file
scratch (`hello.*`, vài bản `.vsix`, `.jfif`). Cần quyết định ở repo đó trước khi
commit bất cứ thứ gì. Ngoài ra `images/preview.png` và `2.UI/media_player.html`
đã commit xong ở cha.

---

## 7. Tài liệu nên đọc trước khi code

- `CLAUDE.md` (cha) — cú pháp và giới hạn hiện hành, đã cập nhật khớp 7 feature.
- `3.code/docs/PLAN.md` — roadmap, Bước 3/4/5/6/7 ghi lại thiết kế và **cả dự
  đoán sai đã bị bác bỏ**.
- `3.code/docs/REPOSITORY-NOTES.md` — 769 dòng nhật ký, bao gồm tất cả bẫy ở mục
  4 và các giới hạn có chủ đích.

---

## 8. Kết quả benchmark (để khỏi đo lại)

7 kernel, checksum khớp. `f32mm_vec` ~34 µs so với scalar ~147 µs, trung bình
~4,08×. Elementwise ~5,89×. `matmul32` còn chậm hơn NumPy khoảng **746×** — đây
là con số thật, đừng sửa thành con số đẹp. Startup 24,6 ms so với CPython
35,8 ms.
