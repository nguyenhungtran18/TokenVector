# BÀN GIAO 2026-10-14 — LICM hoàn thành (và một lớp bug mới)

## 0. TRẠNG THÁI: xong, mọi gate xanh, đã commit

```
vong             IL_IDENTICAL
testkit_gate     123/123  BUILDFAIL=0 TESTFAIL=0 ILFAIL=0 NEG=31/31
dang_ky_gate     PASS (0 vi phạm)
lint_rules_gate  PASS (8/8, 0 false positive)
perf_gate        PASS
```

Commit: `faed5ff` (LICM), `b79e797` (plumbing `locals_decl`), `0c85d08` (việc
phiên trước: int_narrow + 2 fix IL + perf_gate).

Working tree sạch (chỉ 2 submodule dirty, không đụng tới).

---

## 1. ĐÃ XONG

### 1.1 Chẩn đoán #5 của handoff trước — **ĐÚNG**

`Ctx.locals_decl` là một list **rỗng chết**: không hàm nào đọc nó, còn
`gen_il_function` lấy `locals_sig` từ một biến **cục bộ khác**
(`il_codegen.tkv:8421`, từ `_first_pass_collect_locals`). Hai danh sách rời
rạc ⇒ bước CODEGEN khai thêm local gì cũng không bao giờ ra file `.il`.

Sửa (`b79e797`): `tao_ctx(locals_decl=locals_decl)` + tính `locals_sig`
**sau** `_codegen_stmts`. Thay đổi **trung tính IL** (vong `IL_IDENTICAL` ngay
vòng đầu) vì chưa bước codegen nào gán thêm local.

### 1.2 LICM chạy thật (`faed5ff`)

Pass trong `control_flow.tkv`, gọi từ `codegen_for` + `codegen_while`, ngay
trước nhãn `start_lbl` (đối với `for`: **sau** bước khởi tạo biến đếm).

Vòng nóng matmul32 (`perf_mm.tkv`), mỗi MAC:

| | IL |
|---|---|
| trước | `ldloc.s 0 / ldarg.s 3 / conv.i8 / mul.ovf / ldloc.s 3 / add.ovf` (6) |
| sau | `ldloc.s 14 / ldloc.s 3 / add.ovf` (3) |

`__licm14` = `i * n`, khai ở `.locals init` như mọi local khác.

---

## 2. BUG GỐC ĐÃ TÌM RA — ĐỌC MỘT LẦN LÀ ĐỦ

> **`codegen_for` KHÔNG cắt `i = i + 1` vào thân vòng trong AST.**
> Nó tự sinh câu lệnh đó ở nhãn `cont_lbl` lúc codegen.

Nên quét thân vòng **không thấy biến đếm**, và `i * m` bị kết luận là bất
biến. Đây **không phải lỗi hình học** mà là mẫu trường hình, và nó phá
**chính compiler khi nó tự biên dịch**:

```python
# gen_il_function
for idx, p in enumerate(sig.params):
    scope.add_arg(p.name, idx + param_idx_base, p.type_ann)
```

`idx` bị nhớ sai ⇒ **mọi tham số đều nhận idx 0** ⇒ `ldarg.s 0` cho tất cả
tham số khác 0. Triệu chứng đo được:

- testkit còn **109/122**;
- một file **15 dòng, không có vòng lặp nào**, chỉ có `if a == b:` →
  `ldarg.s 0 / ldarg.s 0 / String::Equals` → `AccessViolationException`.

Sửa: `_LICM_DEM_VONG` — bảng kind → trường chứa biến đếm, gộp vào `biend`
ngay sau `_licm_quet`. (`while` không cần: người dùng tự viết `i = i + 1`
trong thân.)

### 2.1 Test ĐÃ chứng minh bắt được bug

`tests/licm_test.tkv` — 6 case: biến đếm của `for`, biến đếm vòng lồng +
vòng ngoài, biến bị gán lại trong thân (trường hợp ngược), biến đếm trong
f-string.

**Đã kiểm chứng:** gỡ `_LICM_DEM_VONG` → build lại → `ArgumentOutOfRangeException`
trong `while_invariant`. Không phải test xanh vờ.

---

## 3. RÀO CHẮN NGÔN NGỮ MỚI PHẢI BIẾT (tiết kiệm hàng giờ)

Cả 4 cái dưới đều **làm hỏng compiler trong chính nó**, không phải chỉ trong
test:

| # | Rào | Triệu chứng nếu vi phạm |
|---|---|---|
| 1 | Slice **trên kết quả gọi hàm** không parse được: `khoa.split('|')[1:]` | `ky vong ']', gap ':'` |
| 2 | **Tuple không có indexer**: `for cap in items_nut(st): cap[1]` | im lặng — `items_nut` trả rỗng ⇒ LICM **không bao giờ chạy** |
| 3 | `KHUON` hóa `str` / `nut` / `ds` là 3 kiểu **khác nhau**. `call` là `o1=TEN, o2=ds`; `index_call` là `o1=nut, o2=ds`; `list_literal` là `o1=ds` | `int("12,34")` ⇒ `Input string was not in a correct format` |
| 4 | `mk2`/`mk3`/`mk4` phải khớp **số ô** của kind. `list_literal` có **1** ô ⇒ `mk2`, dùng `mk3` là lỗi arity lúc biên dịch | `goi 'mk3' voi 2 tham so` |

Rào 2 đáng nhớ nhất: **sai âm thầm, không báo lỗi** — biểu hiện là "tối ưu
không bao giờ chạy", dễ quy cho "tối ưu không hiệu quả".

---

## 4. VỀ `vong.exe` (câu hỏi lặp lại nhiều lần trong phiên)

Một lần chạy = **hai lần tự biên dịch toàn bộ compiler**:

1. Gộp 133 file → `build/selfhost/tv_gop.tkv` ≈ 2,9 MB / 61.000 dòng.
2. `g1` = `dist\tkvc-tv.exe` biên dịch nguồn đó → `g1.il` ≈ 13 MB.
3. `g2` = `g1.exe` biên dịch **lại chính nó** → `g2.il` ≈ 13 MB.
4. `ilasm` chạy 2 lần để lắp 2 file `.exe`.

⇒ **5–7 phút / vòng**, và phải chạy lại lần nữa mỗi khi in
`IL KHAC NHAU` (đó là bình thường: compiler tự nâng cấp). Tổng một thay đổi
compiler ≈ **12–20 phút**.

**Nếu `dist\tkvc-tv.exe` đã hỏng** (compiler cũ có bug làm hỏng nguồn mới thì
vong sẽ đỏ vĩnh viễn): copy lại từ bản đã commit —

```powershell
Copy-Item .\Release\dist\tkvc-tv.exe .\dist\tkvc-tv.exe -Force
```

rồi chạy `tools\vong.exe` cho tới khi `IL_IDENTICAL`. Đã dùng để thoát dây
chuyền 2 lần trong phiên này.

---

## 5. KẾT QUẢ ĐO ĐƯỢC — ĐỌC CẨN THẬN

| | |
|---|---|
| IL vòng nóng matmul32 | 6 → 3 lệnh/MAC (−50% phần chỉ số của `a[...]`) |
| `perf_mm` (perf_gate) | +0,7% — **trong nhiễu đo** |
| `perf_f32mm` / `perf_e2e` | +0,1% / 0,0% |

**LICM rút được IL thật nhưng chưa thấy được trong thời gian chạy.** Lý do
khớp với bản đồ headroom của handoff trước (§4.1): matmul32 **96% thời gian
là bounds-check + `get_Item`**, không phải số học. Cắt 3 lệnh ALU trong ~27
lệnh/MAC không đủ đổi hệ số.

**Chưa đổi baseline** (`tools/perf/baseline.txt`) — đúng, vì chưa có cải thiện
đo được. Đừng `-Update` khi chưa có ý định.

---

## 6. VIỆC CÒN DỞ

| việc | ghi chú |
|---|---|
| **`compiler_py` đồng bộ** | Chưa có `khuon_dt`, `conv.ovf.i4/i8`, `int_narrow`, `aggressiveinlining`, **LICM**. Sửa ở repo riêng **rồi** `compiler_py\build_tkvc.ps1 -DistDir .\dist -BuildDir .\build`, không build thì gate đo compiler cũ |
| **Bỏ bounds check (`f32buf`)** | Vẫn là tiềm năng lớn nhất: 96% thời gian matmul32. LICM đã lấy phần "số học thừa", phần còn lại là bounds check |
| **LICM: mở rộng phạm vi** | Hiện chỉ `+ - *` trên biến vô hướng. `//` cần phân tích chống chia 0; `%` tương tự. Cân nhắc `f32buf` vì đó là đường thật sự còn dư |
| **LICM: chống chạy lại** | `_licm_viet_stmts` sửa **tại chỗ** row câu lệnh (`dat_nut`). Nếu `gen_il_program` gọi lại `gen_il_function` cho cùng một AST (vòng fixpoint monomorphization) thì lần 2 sẽ thấy `__licmN` đã bị thay và có thể nhớ tiếp. **Hiện chưa xảy ra** (testkit xanh), nhưng đây là ẩn số lớn nhất còn lại — nếu ai đó sửa vòng fixpoint thì phải kiểm lại |
| **Perf gate nhạy hơn** | Dao động 3–4%, ngưỡng 7%. Đã thấy một lần báo `TUOT 7.8%` rồi lần sau `PASS` |
| **Kernel AXPY vào benchmark** | `v_*8` + `aggressiveinlining` nhanh 2.11x nhưng chưa kernel nào đo đường này |

---

## 7. LƯU Ý VẬN HÀNH

- Sau **mọi** sửa `compiler_bootstrap/`: `tools\vong.exe` cho tới khi
  `IL_IDENTICAL`, rồi `tools\testkit_gate.ps1`. `IL KHAC NHAU` là bình thường
  (tiến hoá), chạy lại là đúng.
- **Dùng `edit` cẩn thận**: nếu `oldString` chỉ là **tiền tố** của một dòng
  (thiếu phần đuôi), phần đuôi còn lại sẽ dính vào dòng cuối của `newString`.
  Đã dính 3 lần, mỗi lần tốn 1 vòng vong (~6 phút) để tìm ra.
  Tương tự: `newString` không được tự thêm/thiếu thụt đầu dòng so với `oldString`.
- Trước khi ghi một file `compiler/il_features/`, kiểm tra **không ghi đè
  module đang sống**.