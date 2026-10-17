# B-05 / B-07 — VẤN ĐỀ PHÁT HIỆN KHI CHẠY LẠI TOÀN BỘ REPO INFERENCE

Ngày: **2026-10-17** (sau khi đã đóng B-01…B-07)
Compiler: `D:\TokenVector\Release\dist\tkvc-tv.exe` build 17:13
Repo kiểm chứng: `D:\TokenVector.Inference` — **build xanh toàn bộ** với compiler mới,
26/26 case, gap 16/16, `--verify-all` PASS trên cả 5 entry point.

Ghi nhận tích cực: B-05 đã cho số đo thật (trước đó mọi thời gian đều là `0`),
B-07 hoạt động và đã thay thế được toàn bộ probe thủ công.

---

## P1 — `gc_collect()` không gọi được ở dạng lệnh độc lập

```tkv
def bench_gc() -> "i64":
    gc_collect()          # <-- loi
```

Lỗi:
```
il_codegen: 'gc_collect(...)' dung o dang lenh doc lap (khong gan bien) -
khong tim thay ham nay trong chuong trinh (goi sai ten?).
```

Nguyên nhân: `push_gc_collect` được đăng ký bằng `register_expr_builtin`
(`il_features/stdlib_sys.tkv:100`) nên hợp lệ ở **vị trí giá trị**, nhưng
`il_features/file_io.tkv:190` (`_BUILTIN_LENH_DOC_LAP`) là whitelist các builtin
được phép gọi **một mình trên một dòng** — tên `gc_collect` chưa có trong đó.

Cách sửa dùng tạm bên downstream: `_gc_ret = gc_collect()`.

**Đề nghị:** thêm `gc_collect` vào `_BUILTIN_LENH_DOC_LAP`
(`il_features/file_io.tkv`). Hoặc bỏ `ldc.i4 0` cuối `push_gc_collect`
và đăng ký nó như một lệnh void.

---

## P1 — `gc_counts()` trả `""` vĩnh viễn → gate không bao giờ đạt

`push_gc_counts` (`il_features/stdlib_sys.tkv:87`) hard-code `ldstr ""`.

Hậu quả bên downstream:
```
[stress] Hot-path endurance 2000 runs: 64516 req/s, GC  (gate: 0/0/0)
```
→ chuỗi `GC ` rỗng, gate `0/0/0` không bao giờ xanh, nhưng chạy vẫn báo pass.

**Đề nghị:** hoặc triển khai thật (`GC.CollectionCount(0/1/2)`), hoặc bỏ builtin
khỏi registry để downstream tự định nghĩa. Giữ một builtin luôn trả giá trị rỗng
là cái bẫy âm thầm.

---

## ĐÓNG

---

## P3 — GÓP Ý CHẨN ĐOÁN (đính chính)

### Annotated local: KHÔNG phải bug, là quy tắc nháy kép

Bản đầu của note này báo "annotated local không biên dịch được" như một lỗi
compiler. **Sai — đã đính chính.**

TokenVector yêu cầu type annotation dùng **nháy kép**:

```tkv
a: "list[f32]" = [1.0, 2.0, 3.0, 4.0]   # OK
b: "list[f32]" = mk()                   # OK
d: "list[f32]" = []                     # OK
d.append(9.0)
```

Cả 3 dạng đều chạy đúng ngay từ đầu. Dùng nháy đơn mới bị từ chối:

```
il_codegen: khong dich duoc dong: "a: 'list[f32]' = [1.0]"
```

Lưu ý: nháy đơn **vẫn hợp lệ trong chữ ký hàm** (`def f(a: 'list[f32]')`) —
repo `TokenVector.Inference` dùng nháy đơn ở mọi chữ ký và biên dịch bình thường.
Chỉ **annotated local** yêu cầu nháy kép.

Góp ý nhỏ: thông báo lỗi nên nhắc quy tắc này, vì dễ bị hiểu nhầm là bug.

---

## P2 — `simd_*` không nhận được kiểu tensor của repo inference

```tkv
a = mk4(1.0)      # list[f32]
ra = mk4(0.0)     # list[f32]
simd_add(a, b, ra)
# -> il_codegen: simd_add(a) can mang rank 1 kieu f32/f64/i32/i64,
#    'a' co dtype=f32 shape=list
```

Kiểu tensor chuẩn của repo (`_nd_f32` trả `list[f32]`) bị từ chối vì `shape=list`,
không phải shape mảng. Nghĩa là B-04 (đóng gói `System.Numerics.Vectors.dll`) chưa
dùng được với repo này: vẫn còn lớp nữa chặn trước khi chạm tới assembly.

**Đề nghị:** cho `simd_*` nhận `list[f32]` (đã có sẵn layout liên tiếp), hoặc công bố
rõ rằng cần kiểu mảng riêng và cung cấp hàm chuyển đổi. Hiện tại không repo nào
dùng được SIMD.

---

## P2 — `--verify-all` bắt buộc phải có entry `main`

Chạy `--verify-all` trên một module thư viện (không có `main`) thì báo:
```
tkv build: file co 165 ham (...), khong ro entry point nao -
dat ten 1 ham la 'main' hoac chi ro entry_name.
```

Và nếu chỉ định entry có tham số phức tạp (`translate(model: 'OnnxModel')`):
```
tham so 'model' co dtype='OnnxModel' shape='record' - CLI tu dong hien CHI ho tro
tham so VO HUONG (i32/i64/f32/f64/str)
```

Nghĩa là **tính năng hay nhất của B-07 chưa dùng được cho module thư viện** — đúng
loại repo cần nó nhất.

**Đề nghị:** khi `--verify-all` được bật, cho phép chạy không cần entry point
(sinh entry giả, không cần tham số thật). Khi đó có thể xác minh 100% thân hàm
của một thư viện chỉ bằng 1 lệnh, thay vì phải tự sinh probe như repo này đã làm.

---

## Trạng thái sau khi đóng B-01…B-07 (đo lại)

| Hạng mục | Trước | Sau |
|---|---|---|
| 26 case + gap 16 | PASS | PASS |
| `build_inference.ps1` | Completed | Completed |
| `--verify-all` 5 entry | (chưa có) | **PASS cả 5** |
| Zero-GC gate | không đo được (stub → 0) | **-728 B** (đo thật, đạt) |
| Cold-start | `0.0 ms` | 78.0 ms |
| Single-sample | `0.0 us` | 32.0 us |
| FP32 vs INT8 | `infx` | 0.357x |

Ghi chú: `bench_gc` phải gọi `gc_collect()` **hai lần** (trước cả khi đo `b0` và
trước khi đo `used`), nếu không thì `GC.GetTotalMemory` trả tổng bộ nhớ chưa thu
gom → báo 802816 B dù runtime thực tế zero-GC.
