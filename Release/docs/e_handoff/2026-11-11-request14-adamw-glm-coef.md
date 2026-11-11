# Reply #14 — `adamw_step_glm` nhận thêm `coef` (bỏ 3 bước phụ khi clip)

**Ngày:** 2026-11-11
**Đáp:** `docs/COMPILER_TEAM_REQUEST14.md` (nhánh Inference)
**Trạng thái:** xong phần compiler + native, đã verify trong repo compiler. Phần
wiring `trainer.tkv` + đo seq/loss thuộc nhánh Inference (xem §6).

---

## 1. Thay đổi API

```
adamw_step_glm(p, m, v, g, n, lr, b1, b2, eps, wd, bc1s, bc2s, coef) -> i32
```

`coef` là **tham số thứ 13 (cuối)**, không phải thứ 5 — chọn vị trí cuối để
diff nhỏ nhất và khớp thứ tự tham số của export native mới. Ngữ nghĩa: kernel
tính `g_eff = coef * g` **ngay trong lượt đọc `g`**, không cấp buffer trung gian;
công thức AdamW, thứ tự tích luỹ, layout `p/m/v` **không đổi**.

**Breaking:** call 12 tham số cũ **không còn biên dịch được** (lỗi
`can dung 13 tham so`). Đây là chủ ý của request — mọi caller phải truyền
`coef` (đường không clip: truyền `1.0`).

## 2. File đã sửa (repo compiler)

| File | Thay đổi |
|---|---|
| `Release\tools\simd_native\tkv_simd_native.c` | `AdamwGlobal` +`coef`; `adamw_f32_range` +`coef` (AVX2 `vg *= vcoef`, đuôi scalar `g[i]*coef`); thân `AdamwStepF32` tách thành `adamw_step_f32_impl(..., coef)`; `AdamwStepF32` (12 tham số) giữ nguyên ABI → gọi impl với `1.0f`; **export mới `AdamwStepF32C`** (13 tham số, `coef` cuối) |
| `Release\compiler_bootstrap\compiler\il_features\simd_feature.tkv` | P/Invoke mới `AdamwNativeC` (`as "AdamwStepF32C"`); `AdamwGlmM` nhận `float32 coef`, `ldarg.s 12`, gọi `AdamwNativeC`; `compile_adamw_step_glm` đòi 13 tham số, đọc `args[12]` kiểu `f32` |
| `Release\tests\f32_list_ops_test.tkv` | 2 call cũ +`coef = 1.0`; **thêm `_glm_coef_case`** (7 assert × 2 bộ) so `adamw_step_glm(coef)` với đường clip cũ `f32_zero` + `f32_addcmul` + `adamw_step`, bit-exact p/m/v. Tổng 28 → **42** assert |
| `Release\tests\negative\adamw_step_glm_on_buf.tkv` | +`coef` (13 tham số) để vẫn bắt đúng lỗi "g phải là list[f32]" |
| `Release\docs\REFERENCE.md` | Hàng `adamw_step_glm` cập nhật chữ ký + hợp đồng bit-exact |

`build\selfhost\tv_gop.tkv` **không sửa tay** — `tools\vong.exe` sinh lại.

## 3. Hợp đồng bit-exact (đã kiểm)

| Điều kiện | So với | Kết quả |
|---|---|---|
| `coef == 1.0` | `adamw_step` (buffer, cùng kernel cũ) | **p/m/v lệch 0 phần tử** (`glm_p_bit/m/v` n64+n37) |
| `coef == 0.0896` / `0.5`, n=64/37 (single-thread) | `f32_zero` + `f32_addcmul(ptl,g,ponl,coef)` + `adamw_step` | **0/0/0** (`coef_*_bit`) |
| `coef == 0.0896` / `1.0`, **n=131072** (đường thread-pool mode 8) | như trên | **0/0/0** (probe riêng, không nằm trong repo compiler) |

Cơ sở: `f32_addcmul` cũ tính `ptl = coef*g*1.0` = một phép nhân fp32 làm tròn
một lần; kernel mới cũng một phép nhân fp32 làm tròn một lần → cùng bit. Khi
`coef == 1.0f` phép nhân là đồng nhất IEEE-754 nên bằng đúng đường cũ.

## 4. Verify trong repo compiler

| Gate | Kết quả |
|---|---|
| `tools\vong.exe` | **IL_IDENTICAL** (một vòng, không cần promote) |
| `tools\testkit_gate.ps1` | **PASS 136/136**, negative **44/44**, ILFAIL 0 |
| `tests\f32_list_ops_test.tkv` | **42/42 PASS** (gồm 14 assert coef mới) |
| Export DLL | `AdamwStepF32` + `AdamwStepF32C` đều có |

Hash bàn giao:

| Artifact | SHA256 | Kích thước |
|---|---|---|
| `dist\tkvc-tv.exe` | `712704151A9969179616D46CD72E2C0BEB365758E60E07ECFF60A8848EDE6564` | 1,757,184 B |
| `runtime\tkv_simd_native.dll` | `1E49BCE24D7D4A8847CEC0BC94E203CE4CD12CD75C4530FF559F4DE995D92478` | 389,120 B |

Bản cũ trước thay đổi: `dist\tkvc-tv.exe` = `E2DDA536…` (backup
`dist\tkvc-tv.exe.bak_coef14`), DLL cũ 388,608 B.

## 5. Chưa đo

Chưa có số `opt` / full step trên nhánh Inference — cần wiring trainer + đo
(bên dưới). Kỳ vọng giữ nguyên như request: `opt` 781 → **~560 ms**,
full step @seq1024 4219 → **~4000 ms**.

## 6. Việc phía Inference (để đạt §5 của request)

1. **DLL phải được sync** vào chỗ P/Invoke resolve — exe test chạy từ `out\`
   nên P/Invoke tìm cạnh exe: copy `Release\runtime\tkv_simd_native.dll`
   (hash `1E49BCE2…`) → `Inference\out\tkv_simd_native.dll`. DLL cũ **không có**
   export `AdamwStepF32C` → `EntryPointNotFoundException` nếu quên.
2. **`AdamW.step()`** (`tv\training\trainer.tkv` + 3 bản mirror) — thay khối
   clip 3 bước bằng một call:

   ```tkv
   # truoc (coef != 1.0):
   #   r1 = f32_copy_to_buf(gl, pgl, self.n)
   #   rzp = f32_zero(ptl, self.n)
   #   rax = f32_addcmul(ptl, pgl, ponl, coef, self.n)
   #   gsrc = ptl
   # sau: truyen thang gl + coef, xoa if/else
   stw = adamw_step_glm(ppl, pml, pvl, gl, self.n,
                        step_size, self.b1, self.b2, self.eps, wde, bc1, bc2s, coef)
   ```

   (Giữ đoạn code cũ trong comment nếu muốn đối chiếu; `pt`/`pone` chỉ còn
   được cấp phát mà không dùng — có thể bỏ cấp phát để lấy lại working set.)
3. Đo lại: `_clip_real.tkv` (bit-identical + ms), `_seq_cfg.txt` 3 seq
   (`bseq_new.exe`), gate 135/135, trainer 15/15, loss EXACT.

## 7. Ghi chú

- `compile_adamw_step` (đường buffer) **không đổi** — vẫn 12 tham số, vẫn gọi
  `AdamwStepF32`; request chỉ xin `coef` cho biến thể `_glm`.
- Không có thay đổi ngữ nghĩa `.tkv` nào khác.
