# SIMD builtins — đo thật trên repo `TokenVector.Inference`

Ngày: **2026-10-17**
Compiler: `dist\tkvc-tv.exe` build 23:58 (sau các commit `simd_gemm` cache blocking / micro-kernel 4x16 / chia luồng 2 chiều)
Máy đo: cùng máy, cùng dữ liệu ngẫu nhiên có seed, cấp phát đo bằng `gc_allocated_bytes()`.

Tóm tắt một dòng: **`simd_gemm` rất tốt (14.6x, 0 B cấp phát) nhưng chỉ nhận ma trận vuông;
`simd_add/sub/mul/scale/axpy` cấp phát ~16 B/phần tử nên vô dụng với runtime Zero-GC.**

---

## 1. `simd_gemm` — dùng được, rất nhanh (256x256)

```
simd_gemm  256^2:   3200 us/op   alloc =      0 B/op
scalar     256^2:  46800 us/op   alloc =      0 B/op
=> 14.6x, ghi vao `ra` trong place, KHONG cap phat
```

Lưu ý về tính đúng đắn: `max|a_scalar - a_simd| = 2.29e-05` trên giá trị ~thousands.
Tức là **KHÔNG bit-exact** với vòng cộng tuần tự của PyTorch — thứ tự tích luỹ khác.
Điều này ổn với suy luận, nhưng **không dùng được** cho đường parity 1e-7 của kế hoạch
huấn luyện (xem `ROADMAP_TRAIN.md` mục 3). Cần chốt trước: đường parity dùng kernel tích
luỹ tuần tự, đường chạy thật dùng `simd_gemm`.

## 2. `simd_add/sub/mul/scale/axpy` — CHẬM HƠN scalar VÀ phá Zero-GC

Đo trên đúng kernel thật của repo (`elementwise_binary` → `_bin_loop`), 3 mảng
`list[f32]` cùng độ dài 1.048.576 phần tử, 20 lần lặp:

```
scalar vong lien tiep   :  3900 us/op   alloc =         0 B
simd_add(a, b, y)       :  9400 us/op   alloc = 16784480 B
=> CHAM HON 2.4x, va cap phat ~16 B moi phan tu
```

Hai vấn đề độc lập, cùng nghiêm trọng:

- **Cấp phát**: `simd_add(a, b, y)` nhận 3 tham số nhưng bên trong vẫn tạo bản sao
  (16.78 MB / 1M phần tử ≈ 4 bản sao con trỏ list). Với runtime Zero-GC thì đây là
  vi phạm trực tiếp — gate "Heap per 500 inferences: 0 B" sẽ đỏ ngay.
- **Chậm hơn scalar**: vòng `y[i] = a[i] + b[i]` do compiler tự vectorize đã đạt
  3900 µus/1M; bản SIMD 9400 µus. Tức là phần scalar hiện tại **không cần SIMD** ở
  đây, và việc nối SIMD vào làm tệ hơn.

Kết luận: **không nối `simd_*` dạng 3 mảng vào bất kỳ kernel nào** của repo này.

## 3. `simd_gemm` không dùng được cho hình dạng thật của repo

Benchmark nóng dùng `M=16, K=256, N=256` (FP32) và `M=16, K=256, N=256` (INT8).
`simd_gemm(a, b, ra, n)` **chỉ nhận ba ma trận vuông cùng cạnh `n`**.

- Hình chữ nhật (M≠N) — phần lớn mô hình thật — không biểu diễn được.
- Nhân ma trận với vectơ (M=1, hình `bench_latency` 1x64x128, `bench_hot` 1x64x64)
  cũng không biểu diễn được.
- Đệm A từ 16x256 lên 256x256 để gọi `simd_gemm` tốn **16x** flops thừa — lãng phí
  nhiều hơn lợi ích 14.6x.

**Đề nghị:** thêm biến thể hình chữ nhật, ví dụ
`simd_gemm_mn(a, b, ra, m, n, k, trans_b)` — có `trans_b` để phục vụ layout
`W[n][k]` (hàng là output feature) mà repo đang dùng ở `fused_matmul_bias_act`.
Thêm `simd_gemv(a, b, ra, n, k)` cho M=1.

Với 2 builtin này, đường FP32 của repo có thể giảm rõ rệt.

## 4. `v_mul8`, `v_load8`, `v_store8`, ... — có tên nhưng KHÔNG tồn tại

`_BUILTIN_LENH_DOC_LAP` trong `il_features/file_io.tkv:75` liệt kê
`v_fill8, v_load8, v_mul8, v_add8, v_sub8, v_mul8_add8, v_store8, v_store4`,
nhưng **không builtin nào trong số đó được đăng ký** ở bất kỳ đâu trong
`compiler_bootstrap/compiler/**`. Gọi thử:

```tkv
v_mul8(a, b, r)
# -> il_codegen: 'v_mul8(...)' dung o dang lenh doc lap -
#    khong tim thay ham nay trong chuong trinh (goi sai ten?).
```

Đây chính là bộ lệnh vector mức thấp cần để tự viết micro-kernel hình chữ nhật
trong `.tkv`. **Đề nghị: đăng ký chúng, hoặc bỏ khỏi whitelist** để không gây hiểu
nhầm. Đây là đường duy nhất để repo tự viết GEMM hình chữ nhật nếu không muốn
compiler thêm `simd_gemm_mn`.

## 5. Bẫy đo lường: lệnh thuần bị nâng (hoisting)

Lặp gọi `simd_gemm(a, b, r, n)` với **cùng tham số** lần nào cũng bị trình tối ưu
nâng khỏi vòng lặp → đo ra `0.0 us/op`. Phải thay đổi một phần tử của đầu vào mỗi
lần lặp mới đo được (đã dùng `a[i*3] = float(i)` trong phép đo ở mục 1).

Ai đọc số liệu benchmark của compiler cần biết điều này.

---

## 6. Việc repo đã làm

- Đã thử nối `simd_add/sub/mul` vào `_bin_loop` của `tv/optimization/kernels.tkv`
  → đo ra chậm hơn 2.4x và cấp phát 16 MB/lần → **đã gỡ hoàn toàn**, repo về trạng
  thái cũ, `run_cases` 26/26 + gap 16/16 vẫn xanh.

## 7. Tóm tắt đề nghị theo thứ tự ưu tiên

| # | Đề nghị | Tác động |
|---|---|---|
| 1 | `simd_gemm_mn(a, b, ra, m, n, k, trans_b)` | mở khoá tăng tốc cho hình dạng thật |
| 2 | Sửa `simd_add/sub/mul/scale/axpy` để ghi tại chỗ, không copy | bỏ được cản trở Zero-GC |
| 3 | Đăng ký (hoặc gỡ khỏi whitelist) các builtin `v_*` | mở đường viết GEMM chữ nhật trong `.tkv` |
| 4 | `simd_gemv(a, b, ra, n, k)` cho M=1 | phục vụ case latency của repo |
