# Request #13 — ZeroListF32: bỏ cấp phát hai lần

**Ngày:** 2026-11-10
**File sửa:** `Release\compiler_bootstrap\compiler\il_features\slicing.tkv`
**Trạng thái:** xong, đã verify. `IL_IDENTICAL`, gate 136/136, negative 44/44.

---

## 1. Kết quả

`zeros_list(n)` với n = 38,597,376 (147.2 MB):

| Nền | Trước | Sau | Cải thiện |
|---|---|---|---|
| .NET Framework 4.8 | 141.7 ms | 1.07 ms | **132×** |
| .NET 10 | 92.2 ms | 16.7 ms | **5.5×** |

Số là best-of-30, đo bằng `now_ms()` trên chính `.tkv` biên dịch ra, không phải
C# mô phỏng. Lặp 3 lần mỗi nền, dao động dưới 5%.

## 2. §7 của request SAI — và tôi đã kiểm bằng thực nghiệm

Request đề nghị `CollectionsMarshal.SetCount`. Ba lý do nó không dùng được:

1. **Không resolve được từ `System.Runtime`.** IL probe gọi
   `[System.Runtime]System.Runtime.InteropServices.CollectionsMarshal` →
   `TypeLoadException` trên **cả** .NET Framework 4.8 và .NET 10.
2. **Không tồn tại trên .NET Framework.** Trên .NET 10 nó nằm trong
   `System.Private.CoreLib` (ver 10.0.0.0, token `7C EC 85 D7 BE A7 79 8E`),
   xác nhận bằng `dotnet new console` + csc. Framework 4.8 không có type này.
3. **Header hiện tại không có extern nào trỏ tới CoreLib.** Thêm vào là đổi
   toàn bộ hợp đồng assembly của compiler, không phải một sửa cục bộ.

§8 (offset 16) cũng không dùng được: `_size` nằm ở offset **24** trên Framework
4.8 và **16** trên .NET 10 — thứ tự field khác nhau (`_items,_size,_version,
_syncRoot` vs `_items,_size,_version`). `ldfld` thẳng vào `_size` →
`FieldAccessException` trên cả hai.

Reflection cũng không: probe reflection chạy đúng trên Framework 4.8 nhưng
`InvalidProgramException` trên .NET 10. Không portable.

## 3. Cách đã chọn

`List<T>` có **đường nhanh ICollection<T>** trong ctor `List(IEnumerable<T>)`:
nếu tham số implement `ICollection<T>`, nó lấy `Count` để cấp backing array
**đúng một lần**, rồi gọi `CopyTo`. Nếu `CopyTo` rỗng thì không có lần chép nào.

Nên: một lớp `TkvZeroSrc` private, sealed, `Count` trả `n`, `CopyTo` **rỗng**.
Backing array do CLR zero-fill sẵn — chính xác cái ta cần, miễn phí.

```il
.method public static class [mscorlib]System.Collections.Generic.List`1<float32> ZeroListF32(int32 n) cil managed
{
  .maxstack 8
  ldarg.0
  ldc.i4.0
  ble TKVZM_RZ
  ldarg.0
  newobj instance void TkvZeroSrc::.ctor(int32)
  newobj instance void class [mscorlib]System.Collections.Generic.List`1<float32>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
  ret
TKVZM_RZ:
  newobj instance void class [mscorlib]System.Collections.Generic.List`1<float32>::.ctor()
  ret
}
```

Chữ ký **không đổi** (`List<float32> ZeroListF32(int32)`), call site không đổi,
không cần `System.Runtime`, không cần `System.Private.CoreLib`, không reflection,
không phụ thuộc layout nội bộ của `List<T>`.

Đã kiểm chạy đúng trên **cả hai** nền với n = 0, 1, 7, 1000, 38597376, -5.

## 4. Test chặn

`Release\tests\zeros_list_scale_test.tkv` — 29 assert, 5 kích thước theo §4.

Ghi chú kỹ thuật khi viết test: `zeros_list` khai return dtype `'i32'` (xem
`compile_zeros_list`), nên `z[i]` trực tiếp bị codegen từ chối. Mọi phép kiểm
phải đi qua tham số `list[f32]` — đúng như production làm (`t_zeros` →
`Tensor(data, ...)`).

Test bắt được: Count sai (nếu ai quay lại `List(IEnumerable)` hỏng), offset
`_size` (nếu ai dùng đường không portable), nhánh `n <= 0` hỏng, và backing
array không ghi được (list "rỗng vỏ").

## 5. Verify

| Gate | Kết quả |
|---|---|
| `tools\vong.tkv` | `IL_IDENTICAL` (g1 == g2 == 14,429,900 ký tự) |
| `tools\testkit_gate.ps1` | **PASS 136/136**, negative 44/44 |
| `Inference\tools\run_cases.ps1` | 22 pass / 4 fail — **giống hệt compiler cũ** |
| `tools\perf_gate.ps1` | FAIL `perf_f32buf` 34.4% — **compiler cũ còn 38.7%** |

Hai dòng cuối là nhiễu có sẵn, không phải hồi quy. `perf_f32buf` không dùng
`zeros_list` (kernel `f32buf` + P6 vectorize). 4 case fail của `run_cases` đều do
`System.Runtime.Intrinsics` thiếu trên .NET Framework — cũng có trước.

## 6. Việc còn lại

- `tv_gop.tkv` **không sửa tay** — nó là output của `ds_gop.txt` (133 file).
  Vòng self-host đã sinh lại nó; sửa tay sẽ bị ghi đè. Nguồn duy nhất là
  `compiler_bootstrap\compiler\il_features\slicing.tkv`.
- `dist\il_features\slicing.tkv` là bản cũ, **không** chứa `ZeroListF32` — bỏ qua.
- `tools\perf_gate.ps1` baseline `perf_f32buf` (165.6 ms) đã lệch khỏi máy này
  từ trước. Nếu muốn gate xanh, chạy `-Update` khi máy sạch tải — nhưng đó là
  quyết định riêng, không thuộc request này.
- Backup compiler cũ: `dist\tkvc-tv.exe.bak_zl13` (SHA256 `7EEF89BE…`).
  Bản mới: `E2DDA536…`. Xoá backup khi đã yên tâm.
