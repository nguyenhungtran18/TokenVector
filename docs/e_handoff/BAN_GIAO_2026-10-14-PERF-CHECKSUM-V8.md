# BÀN GIAO 2026-10-14 (phần 2) — perf gate có thật sự so checksum, và `v_*8` không phải SIMD

Bắt đầu từ bàn giao 2026-10-14-LICM (LICM xong, mọi gate xanh). Phiên này
**không thêm tối ưu nào** — mục tiêu là đo lại những thứ đã được ghi là xanh,
và 2 trong số đó **không đúng**.

---

## 0. TRẠNG THÁI: xong, mọi gate xanh

```
vong             IL_IDENTICAL   (2 lan, ca 2 lan vong dau)
testkit_gate     123/123  BUILDFAIL=0 TESTFAIL=0 ILFAIL=0 NEG=31/31
dang_ky_gate     PASS (0 vi pham, 2085 ham)
lint_rules_gate  PASS (8/8, 0 false positive)
perf_gate        PASS (4 kernel, kem checksum)
```

---

## 1. PHÁT HIỆN LỚN NHẤT: `v_*8` **KHÔNG phải SIMD**, và con số 2.11x là do đo sai baseline

Handoff 2026-10-13 §1.5 ghi: *"`v_*8` + `aggressiveinlining` nhanh hơn 2.11x"*.
Con số đó **đúng với so sánh đã làm, nhưng so sánh sai** — nó so `v_*8` với
`list[f32]`, tức là vừa đổi **8-lane** vừa đổi **substrate bộ nhớ**.

Đo lại, cả ba cùng đọc/ghi bộ đệm native 4 MB, cùng phép `y = 2.5x + 1.25`,
1 M phần tử f32, best-of-5 × 8 reps:

| | ms | |
|---|---|---|
| `v_*8` (8 lane) | **2.35** | |
| **native scalar** (`read_f32`/`write_f32`) | **2.55** | nhanh hơn `v_*8` chỉ **1.08x** |
| `list[f32]` | 4.47 | đây mới là cái "2.11x" so với |

Ổn định tuyệt đối (3 lần chạy: 2.3521 / 2.3522 / 2.3533).

### 1.1 Vì sao — đọc IL, không phải suy đoán

Đếm trong `.locals`/thân vòng lặp:

| | IL / 8 phần tử |
|---|---|
| `v_*8` | **213** |
| native scalar | **39** |

Và trong 213 lệnh đó **không có lệnh SIMD nào**: `ldind.r4` × 16, `stind.r4` × 8,
`stfld VBuf8::fN` × 8. Tức `v_load8` vẫn **đọc từng lane một** như scalar — khác
duy nhất là nó ghi vào 8 field của 1 struct, rồi `MulAddS` (có `aggressiveinlining`)
lo phép số học trên cả 8 field.

⇒ `v_*8` **có nhiều IL hơn scalar gấp 5.5 lần** và **không dùng lệnh vector**.
Cải thiện 1.08x đến từ việc JIT gộp được 8 phép, không từ SIMD.

### 1.2 Hệ quả

- Đừng ghi "`v_*8` nhanh 2.11x" vào bất kỳ tài liệu nào nữa (đã sửa tại chỗ trong
  `BAN_GIAO_2026-10-13-SIMD-IL-DENSITY.md`).
- Muốn **SIMD thật** thì phải sửa `vector_block.tkv`: phát `ldind`/`stind` 32 byte
  liên tục thay vì 8 lần đọc 4 byte, hoặc chuyển `VBuf8` sang
  `System.Numerics.Vector<float>`. Đó là việc khác, chưa làm.

---

## 2. `perf_gate.ps1` **KHÔNG hề so checksum** — đúng cái nguyên lý nó tự tuyên

Handoff 2026-10-13 §1.4 và `CLAUDE.md` đều ghi gate "so checksum, lệch thì fail".
Đọc code: `Measure-One` **có** lấy dòng output, nhưng dòng đó chỉ được `Write-Output`
ra màn hình và **không bao giờ được so với baseline**. Baseline chỉ lưu `ten/ms`.

⇒ Đúng cái rủi ro mà gate sinh ra để chống — *"nhanh mà tính sai"* — **hoàn toàn
không được canh**. Một đổi compiler làm sai kết quả vẫn PASS nếu không chậm hơn.

**Đã sửa**: baseline 3 cột `ten / ms / checksum`, so trước khi so thời gian.
Baseline 2 cột cũ vẫn đọc được (chỉ bỏ qua bước so checksum).

### 2.1 ĐÃ kiểm chứng gate bắt được bug thật (không phải xanh vờ)

Cố tình làm `perf_mm` tính sai — thêm `+ 1.0` vào biểu thức MAC:

```
perf_axpy           59.7      60.1     -0.8%  ok
perf_e2e            50.0      50.6     -1.1%  ok
perf_f32mm          38.5      38.8     -0.8%  ok
perf_mm             27.6      27.4      1.0%  CHECKSUM LECH
    hien tai : sum=32769.0
    baseline : sum=1.0
GATE: FAIL
```

Chú ý: **thời gian không đổi** (1.0%). Không có checksum thì lần này PASS trắng.
Đã hoàn phục `perf_mm`.

---

## 3. Thêm kernel `perf_axpy` — đường `v_*8` trước đó **không gate nào đo**

`tools/perf/perf_axpy.tkv`: `y[i] = alpha*x[i] + beta`, 8 lane/lần, trên native
memory. Đây là **định dạng scaled+shifted copy**, KHÔNG phải AXPY thật — khoi
vector chỉ có một thanh ghi ngầm, `v_load8` ghi đè nó, `v_add8` nhận vô hướng
nên không diễn đạt được `acc + va*vb` (đã biết từ handoff trước).

- **Bit-exact so với scalar**: kiểm chứng 4096/4096 phần tử.
- Thời gian ~60 ms — ngang các kernel cũ (chạy 24 reps, checksum đọc **ngoài**
  vòng lặp: bản đầu đặt checksum trong vòng quét hết `n` phần tử, chiếm 87%
  thời gian và làm sai thứ cần đo).

---

## 4. LICM: guard chống chạy lại (mục "ẩn số lớn nhất" của handoff trước)

Handoff 2026-10-14 §6 cảnh báo: `_licm_viet_stmts` sửa AST **tại chỗ**; nếu
`gen_il_function` chạy 2 lần trên cùng AST (vòng fixpoint monomorphize gọi lại
`gen_il_program` trên toàn bộ `sig_body_pairs`), lần 2 sẽ thấy `__licmN` đã bị
thay.

**Đã thêm guard** (`control_flow.tkv`): `_LICM_DA_LAM` — set chỉ số vòng đã
LICM, đánh dấu **cuối cùng** sau `_licm_viet_stmts` (mọi nhánh thoát sớm phía
trước đều chưa sửa gì nên thử lại là an toàn).

**Điểm dễ sai — reset:** set lưu **chỉ số row**, mà `reset_pool()` xoá row mỗi
chương trình. Quên xoá thì 1 vòng lặp hoàn toàn khác ở chương trình sau bị coi
là "đã LICM" và mất tối ưu — im lặng, không báo lỗi. Vì vậy `_licm_reset()`
được gọi **cùng dòng** với `reset_pool()` trong `gen_il_program`.

Trung tính IL: `vong` = `IL_IDENTICAL` ngay vòng đầu, testkit 123/123.

**Còn lại:** chưa tìm được repro thực sự (đường `pre_parsed_stmts` của closure
đã thử, chạy đúng). Đây là **phòng thủ**, không phải sửa bug đang xảy ra.

---

## 5. `tkv_guide verify` in ra lệnh không chạy được

`verify` in 2 lệnh cho người dùng chạy, nhưng cả 3 đều sai:

| in ra | thực tế |
|---|---|
| `cd D:\TokenVector\3.code` | `3.code/` **đã bị xoá 2026-10-02** |
| `dist\tkvc.exe build ... --out ... --entry` | CLI của `tkvc-tv.exe` là **positional**: `<src> <out> <entry>` |
| `tools\parity_probe\run.ps1` | đã tách sang repo `TokenVector.TestOracle` |

Đã sửa (`_repo_root()` dò ngược 4 cấp từ `argv[0]`, nên chạy được cả bản
`tools/` lẫn bản Release `dist/bin/`). Ngoài ra xoá 2 nhánh tìm `3.code/` chết
trong `ref_path()`.

---

## 6. BÀI HỌC — cái đo được mới đáng tin

Hai phát hiện lớn nhất phiên này (**checksum không hề được so**, **`v_*8` không
phải SIMD**) đều đến từ việc **đọc lại code của chính gate/tài liệu đó**, chứ
không phải từ thêm test. Cả hai đều là trường hợp "tài liệu mô tả một hành vi mà
code không thực hiện".

Cụ thể:
- `perf_gate` ghi "so checksum" ở cả handoff lẫn `CLAUDE.md` — nhưng code chỉ
  `Write-Output`. Tài liệu đúng ý, code chưa làm.
- Handoff ghi "`v_*8` nhanh 2.11x" kèm bảng số — nhưng bảng đó so với
  `list[f32]`, và không ai hỏi "so với cái gì là đúng".

⇒ Khi ghi kết quả đo, **luôn ghi rõ đối chiếu với cái gì**, và khi viết "gate
đã so X" thì phải mở code ra xác nhận X thật sự được so.

---

## 7. VIỆC CÒN DỞ

| việc | ghi chú |
|---|---|
| **SIMD thật** (cả `f32x4` lẫn `v_*8`) | `f32x4` phát **method call** `Vector4::op_Addition`; `v_*8` phát **lệnh scalar** từng lane. Cả hai **không phải lệnh vector**. Đường thật sự còn dư: phát `ldind`/`stind` 32 byte liên tục. Việc lớn, chưa bắt đầu |
| **Bỏ bounds check** | Vẫn là phần lớn thời gian `perf_e2e`/`perf_mm`. Chưa động tới |
| **LICM: mở rộng phạm vi** | `//` cần phân tích chống chia 0; `%` tương tự |
| **Perf gate nhạy hơn** | Đo được nhiễu máy **10-13%** ngay trong phiên này (3 kernel FAIL đồng loạt rồi 3 lần sau PASS 1-4%). Cân nhắc tăng `-Runs` hoặc lấy trung vị thay vì best-of |
| **`vector_block_test` flaky 1 lần** | Xem mục 8 - chưa rõ nguyên nhân chính xác |

## 6b. BỔ SUNG SAU ĐÓ — `perf_f32buf`: P6 nay có gate

`tools/perf/perf_f32buf.tkv` — kernel thứ 5, đo đường `f32buf` + P6. Trước đó
**không kernel nào** chạm vào cả hai (~600 dòng trong `control_flow.tkv`).

**Bằng chứng gate có tác dụng** (không phải xanh vờ): đổi thành
`r[i] = a[i] * 2.0 + b[i]` — P6 **từ chối** vì có hằng số nên chạy scalar:

```
perf_f32buf   471.7   232.2   103.2%   CHECKSUM LECH
```

Tức đường vector hoá đóng góp đúng **một nửa** thời gian kernel. Nếu gate chỉ
đo thời gian mà không so checksum thì lần này đã lọt.

**P6 đo lại còn 1.57× so với scalar `list[f32]`** — khớp con số 1.6–2.1× trong
plan. Nhưng **không phải SIMD thật**: IL là method call `Vector4::op_Addition`.

**Hai kết quả phụ đáng ghi:**

- `f32buf` **chỉ là local** — không truyền được qua tham số hàm. Muốn dùng P6 thì
  vòng phải nằm trong hàm. (Giới hạn này chưa được ghi ở tài liệu nào.)
- `n` là **local** ⇒ biến đếm `i` thành `TkvInt` và `i*4` phải qua
  `TkvInt::MulSlow`/`ToI64`. **Nhưng thời gian y hệt** (1.23 vs 1.18 ms) — JIT
  chịu được. Nên P6-6 ("nâng `i*4` ra khỏi vòng vector") **không đáng làm**;
  đóng lại.

**Bẫy đo đã gặp ở kernel này** (lần thứ 3 về chuyện này):

1. Không đọc kết quả ⇒ JIT xoá cả vòng lặp.
2. Dữ liệu không đổi giữa các vòng ⇒ JIT nâng vòng lặp ra khỏi vòng đo. Trên
   `list[f32]` điều này ra số **vô lý** (0.11 ns/phần tử) và "P6 chậm hơn
   scalar **10.8×**". Trên `f32buf` thì **không** xảy ra — bộ đệm không do
   GC quản lý nên JIT không nâng được (đo: 1.2249 vs 1.2247 ms khi đổi/không
   đổi). Cùng một phép tính, hai kết luận hoàn toàn khác — nên phải đo từng
   substrate.

3. **Mỗi kernel có ~50 ms startup** không thuộc phần đo. Ban đầu `reps=30` chỉ
   làm P6 chiếm 40% thời gian process ⇒ hồi quy 17% chỉ tách được 6.7%, ngay
   ngưỡng 7%. Tăng lên `reps=150` thì P6 chiếm 77%. **Chọn `reps` phải tính
   tới tỷ lệ phần đo / tổng**, không chỉ nhìn thời lượng process.

> **`compiler_py` KHÔNG còn là việc dở** (2026-10-14, chủ repo đã dừng phía đó).
> Xem mục "Hai compiler" trong `CLAUDE.md`. Sửa đổi chưa commit trong
> `compiler_py/compiler/il_features/operators.tkv` được **giữ nguyên**, không
> đụng tới.

---

## 8. MỘT LẦN `vector_block_test` FAIL RỒI LẠI PASS — đã truy, không phải hồi quy

Sau khi sửa xong, `testkit_gate` báo `TESTFAIL vector_block_test.tkv` (122/123).
Đã điều tra thay vì coi là nhiễu rồi bỏ qua:

| cách kiểm | kết quả |
|---|---|
| chạy `vector_block_test.tkv` tay | 35/35 PASS, exit 0 |
| qua đúng cơ chế `Start-Process` + redirect của gate, 40 lần | output rỗng 0, output ngắn 0 |
| **build lại + chạy, 25 vòng** | build fail 0, test fail 0 |
| `testkit_gate` đầy đủ, 9 lần liên tiếp sau đó | PASS 123/123 cả 9 |

Lần FAIL xảy ra **ngay sau khi `vong.exe` vừa chạy xong** (nó gộp 133 file và
biên dịch 2 vòng, 5-7 phút, ăn CPU). Cùng loại nhiễu máy đã thấy ở perf gate.

**Chưa tìm ra nguyên nhân chính xác** — không loại trừ được race giữa lúc gate
đọc file output và lúc tiến trình kết thúc. Nhưng chắc chắn **không** phải
hồi quy của thay đổi hôm nay: cùng một binary đó chạy 25 vòng build+run sạch
và 9 vòng gate sạch. Nếu thấy lại, hãy chạy lại trước khi điều tra sâu.

---

## 9. LƯU Ý VẬN HÀNH

- Sau **mọi** sửa `compiler_bootstrap/`: `tools\vong.exe` tới khi `IL_IDENTICAL`,
  rồi `tools\testkit_gate.ps1`. `IL KHAC NHAU` là bình thường (tiến hoá).
- **Perf gate có nhiễu.** Đừng kết luận hồi quy từ 1 lần chạy — chạy lại 2-3 lần.
- Đừng `-Update` baseline khi chưa có ý định: nó ghi đè luôn cả số của các
  kernel không liên quan.
- Dùng `edit` cẩn thận: `oldString` chỉ là **tiền tố** của một dòng sẽ làm phần
  đuôi dính vào dòng cuối của `newString` (đã dính 3 lần trong phiên trước).
- Trước khi ghi một file `compiler/il_features/`, kiểm tra **không ghi đè module
  đang sống**.