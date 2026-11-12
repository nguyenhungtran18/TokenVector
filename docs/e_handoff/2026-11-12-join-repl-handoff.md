# Handoff 2026-11-12 — string row: join/split, RepL fast path, .NET 10 JIT rejection

## Bối cảnh

Sau khi đo lại benchmark (2026-11-11, 1.0.13), row `string` thua NumPy 1.95x.
Yêu cầu: "thua cấu trúc → thì khắc phục cấu trúc". Kết quả: build được nhanh
2x, nhưng `join` không lấy lại được vì .NET 10 JIT từ chối code IL mới →
revert về 1.0.13; giữ lại chỉ `RepL` fast path.

## Phát hiện nền tảng

**Exe do `tkvc-tv` sinh ra chạy trên .NET Framework 4.8** (CLR
`4.0.30319.42000`), không phải .NET 10 — dù có `runtimeconfig.json`
net10.0. Chuỗi hệ quả:

1. Không có `String.Create` / `Span<T>` / `CollectionsMarshal` →
   `string` khó ghép nhanh; mọi giải pháp phải dùng BCL có sẵn hoặc
   `Marshal`/pin + `cpblk`/`Buffer.MemoryCopy`.
2. `cpblk` trong IL **không được JIT inline trên Framework** (gọi
   memcpy thư viện); tự viết memcpy 8/4/1-byte inline → JIT 4.8 báo
   `InvalidProgramException`.
3. Các suite cần `System.Runtime.Intrinsics`/`Vector.Widen` không chạy
   được trên Framework → **chạy trên .NET 10** qua `dotnet` + runtimeconfig
   (như `gate_f32.sh` làm). Đây là nơi **.NET 10 JIT reject** IL mà
   Framework chấp nhận.

`tools\vong.exe` in `IL_IDENTICAL` **không chứng minh program chạy đúng**
— chỉ chứng minh compiler biên dịch lại chính nó ra cùng IL; chương trình
biên dịch ra chạy trên Framework có thể chết trên .NET 10.

## Những gì đã làm (2026-11-12)

### JoinList (REVERTED)

`TkvStr::JoinList` (1 chỗ gọi từ 3 call site trong `string_join.tkv`):
allocate result 1 lần (`String(char, total)`), pin destination + từng
source (pinned locals), `_items` đọc 1 lần qua reflection, copy bằng
`Buffer.MemoryCopy`.

- Framework 4.8: hoạt động đúng, join ~2.1–2.9 ms (memory-copy từ C#
  `fixed` tương đương = 1.16 ms — vẫn chậm hơn CPython/NumPy ở join).
- .NET 10: **`NullReferenceException`/`InvalidProgramException`**
  trong `_bits_line` → `ckpt_save` (inference suite `gpt2_train_tests`
  chạy trên .NET 10). Các suite khác PASS; 1.0.13 PASS
  (`cases=5 fails=0`).
- Probe độc lập chạy trên cả hai runtime vẫn ổn → lỗi chỉ xảy ra ở biên
  dịch/thi hành thật trên .NET 10; chưa cô lập được lệnh IL gây lỗi.
- **Quyết định: revert `string_join.tkv` + `tkvstr.tkv` về 1.0.13.**
  Verified: compiler gate 136/136, `f32_list_ops_test` 42/42, inference
  gate 135/135, `trainer_tests` 15/15 fails=0.

### RepL fast path (KEPT)

`TkvSlice::RepL` (`[x]*n`, total ≥ 64): allocate `T[]`, fill bằng
**doubling** `Array.Copy`, cài `_items` + `_size` qua reflection (giống
`simd_feature.tkv`). `[chunk]*200000` **0.99 → 0.51 ms**
(CPython 0.351 ms). Verified cả 2 runtime, checksum `1625000` giữ nguyên.

### Benchmark row `string` (KETQA.md)

`string` = **3.414 ms** (từ 3.660), `string scan` = **3.326 ms**,
`string scan only` = **0.245 ms** (NumPy 1.788 → **TKV 7.29x**, đây là
*phép tách đo*, không phải tăng tốc). vs CPython geo **2153x**, thấp nhất
`string` **83.7x**. vs NumPy geo **1.48x**; `string` vẫn thua 1.50x.

## Trạng thái & commit

- `main` @ `7767e81` (chứa JoinList — LẠC HẬU; đã sửa tiếp ở working
  tree).
- Sau khi revert: `string_join.tkv`/`tkvstr.tkv` = 1.0.13; `slicing.tkv` =
  RepL mới; `dist/tkvc-tv.exe` = build IL_IDENTICAL mới. Status sạch chờ
  commit.
- `.NET 10 JIT reject JoinList` là blocker của mọi tối ưu `join` quản lý
  (managed) — cần thiết kế lại (native `tkv_str_join` trong
  `tkv_simd_native.dll` pin dest + từng string) nếu muốn thắng thật.

## Verify sau revert

| Gate | Kết quả |
|---|---|
| `tools\vong.exe` | IL_IDENTICAL (round 2) |
| `tools\testkit_gate.ps1` | PASS 136/136, negative 44/44, ILFAIL 0 |
| `tests\f32_list_ops_test.tkv` | 42/42 |
| Inference `tools\gate_f32.sh` (LF copy qua WSL) | **135/135 PASS** |
| `tv\tests\trainer_tests.tkv` | 15/15 fails=0 |

## Việc chưa làm / lưu ý

- Handoff này + commit local (không push).
- Chưa đóng gói 1.0.14 (nếu muốn: cần re-run toàn bộ + `pack.ps1` +
  `vsce`, smoke-test).
- Inference `out/` và repo-root probe files là rác → đã dọn trong cùng
  session.
- Bài học đo: `.NET 10` ≠ `Framework 4.8` về strict IL; đừng tin IL chạy
  được ở một runtime là chạy được runtime kia; luôn chạy cả 2 end-to-end
  trước khi đóng gói.
