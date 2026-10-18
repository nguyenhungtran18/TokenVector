# BÀN GIAO 2026-10-18 — SIMD GEMM thật (AVX2+FMA) thắng NumPy/OpenBLAS tới n=768

Tiếp nối chuỗi từ `BAN_GIAO_2026-10-14-PERF-CHECKSUM-V8.md` (kết luận khi đó:
*"SIMD thật KHÔNG THỰC HIỆN ĐƯỢC trên target này"*). Kết luận đó **đã lật** ở
phiên hôm nay: SIMD thật **làm được**, và làm bằng **kernel C native** gọi qua
P/Invoke — không đụng tới đường `Vector4`/`v_*8` bị JIT từ chối (mục 7 của handoff
cũ vẫn đúng, nhưng có đường vòng).

---

## 0. TRẠNG THÁI: xong, mọi gate xanh

```
testkit_gate     125/125  BUILDFAIL=0 TESTFAIL=0 ILFAIL=0 NEG=31/31   PASS
test_sgemm       err=0 moi kich thuoc (n=32..1024), ca f32 lan f64
run_benchmark    checksum khop NumPy (n32=937.174, n128=6571.537)
```

Commit (đã push lên `main`):

| commit | nội dung |
|---|---|
| `0ca755b` | SGEMM đa luồng (thread pool) + register blocking 8×8 trong kernel C |
| `b0ebd49` | Cache blocking kiểu Goto (j-block NC + k-block KC, pack B panel) |
| `85cec06` | `simd_gemm` trên `list[f32/f64]` bỏ copy vào/ra (reflection `_items`) |
| `7366cc2` | **Dùng số core VẬT LÝ** (không HT) + **micro-kernel 4×16 f32 / 4×8 f64** |
| `782851e` | **Padding panel B** + **chia luồng 2 chiều** + HT cho n≥512 → **thắng NumPy ở MỌI n** |

---

## 1. MỤC TIÊU VÀ CÁCH TIẾP CẬN

`simd_gemm(a, b, r, n)` trong TokenVector phải nhanh hơn NumPy. Đường thuần IL
bất khả thi (JIT .NET Framework từ chối lệnh SIMD thô trên struct — handoff cũ
mục 7). Vì vậy:

- Viết kernel **C** (`tkv_simd_native.c`) biên dịch sẵn lên **AVX2 + FMA**, xuất
  `SgemmF32/SgemmF64` qua `__declspec(dllexport)`.
- Compiler TokenVector sinh IL gọi qua **P/Invoke** (`pinvokeimpl(... winapi)`,
  x64 Windows một convention duy nhất).
- Đầu vào là `list[f64]` → phải lấy mảng nền **không copy**. Dùng reflection vào
  field `List<T>._items` (xem mục 5).

---

## 2. KIẾN TRÚC KERNEL (`Release/tools/simd_native/tkv_simd_native.c`)

Hằng số tile (đổi được lúc build bằng `/DGEMM_KC=...` v.v.):

| | KC (k-block) | MC (i-block) | NC (j-block) | micro |
|---|---|---|---|---|
| f32 | 64 | 64 | 64 | **4×16** |
| f64 | 64 (KC64) | 32 (MC64) | 64 (NC64) | **4×8** |

Luồng gọi: `SgemmF32` → `tkv_nthreads(n)` → (1 luồng) `gemm_rows_f32(0,n)`
hoặc (nhiều luồng) `tkv_run_mt` chia **hàng** cho thread pool có sẵn
(`tkv_worker` + `CreateEvent`, tạo **một lần** qua `InitOnceExecuteOnce` — tránh
~0.6 ms tạo thread mỗi lần gọi).

`gemm_rows_f32` (kiểu Goto đơn tầng):

```
memset(C, 0)
for jc in 0..n step NC:
  for pc in 0..n step KC:
    pack_b_f32(b, bp, ...)      // bp = KC×NC, __declspec(thread)
    for ic in i0..i1 step MC:
      micro_f32(a, n, bp, c, n, mc, nc, kc)
```

- **A đọc trực tiếp theo hàng** (`a[ii*n + p]`, liên tục theo `p`) — không pack.
- **B pack thành panel** `KC×BPL` (`GEMM_BPL = NC + 4`, f64 `NC64 + 2`) để nằm
  trong L1/L2 và tái dùng cho mọi i-block; **+4 là đệm phá stride lũy thừa 2**
  (xem mục 6b.1 — đòn đắt nhất ở n lớn).
- Bộ đệm `bp` là `static __declspec(thread)` (mỗi thread một bản).

**Chia việc cho thread (`tkv_run_mt`):** lưới **2 chiều `rows × cols`** (mục
6b.2). Hàng chia làm tròn **bội số 8** (`align`); cột chia làm tròn **bội số NC**.
Mỗi job mang `(i0,i1,j0,j1)`; `gemm_rows_*` chỉ zero/ghi trong dải cột của mình
(an toàn, không đua). Trước khi có bước làm tròn hàng, n=192 bị 0.36 ms (hàng
không chia hết → micro-kernel rơi hết vào nhánh đuôi scalar).

---

## 3. PHÁT HIỆN LỚN NHẤT: **hyperthread**, không phải cache tile

Số liệu ban đầu (16 luồng, 8×8, trước mọi thứ): n=512 = **1.47 ms**, NumPy 0.80 →
thua. Các lần quét KC/NC/MC (mục 4) **không cải thiện gì** (1.07–1.85 ms). Cache
blocking đơn tầng không phải nút cổ chai.

Đo scaling (n=512, 1→16 luồng): `6.20 / 3.57 / 1.99 / 1.05(8) / 1.13(16)` —
**8 luồng nhanh hơn 16 luồng**. Đó là dấu hiệu hyperthread: máy có **14 core vật
lý / 28 logical**, đẩy 16 luồng vào 14 core gây tranh chấp băng thông L3.

Đổi sang **số core vật lý**:

```c
GetLogicalProcessorInformationEx(RelationProcessorCore, NULL, &len); // dem
```

Kết quả tức thì: n=512 **1.05 → 0.70 ms** (14 luồng). Quét lại 6/8/10/12/14/16 →
14 luồng thắng đúng, 16 luồng tệ nhất ở mọi n.

> Env: `TKV_GEMM_THREADS=0` (mặc định) = **auto**. Ban đầu auto = số core **vật
> lý** (mục 3); về sau (mục 6b.2) auto = vật lý cho `n<512`, và **HT (2×vật lý)**
> cho `n≥512` — nhưng **chỉ nhờ đã padding panel B** (mục 6b.1) HT mới có lợi.
> Đặt >0 để ép. `TKV_GEMM_MIN_N` (mặc định **96**) = ngưỡng `n` để bật đa luồng.

**Bài học:** trước khi tối ưu cache tile, phải chắc chắn topology luồng đúng.
Đây là thứ đắt nhất và dễ bỏ sót nhất.

---

## 4. MICRO-KERNEL 4×16 / 4×8 — vì sao FMA-bound đánh bại 8×8

Phân tích cổng nạp (Haswell: 2 load + 2 FMA/chu kỳ, 16 thanh ghi ymm):

| micro | acc ymm | load uop/p | FMA/p | nút cổ chai | FLOP/cyc |
|---|---|---|---|---|---|
| f32 **8×8** | 8 | 8 broadcast + 1 load = 9 | 8 | **load** (4.5 cyc) | ~28 |
| f32 **4×16** | 8 | 4 broadcast + 2 load = 6 | 8 | **FMA** (4 cyc) | **32 (đỉnh)** |
| f64 8×4 | 8 | 8 broadcast + 1 load = 9 | 8 | **load** (4.5 cyc) | ~14 |
| f64 **4×8** | 8 | 4 broadcast + 2 load = 6 | 8 | **FMA** (4 cyc) | **16 (đỉnh)** |

Mấu chốt: **NR rộng hơn** (16 cho f32, 8 cho f64) làm **mỗi broadcast A phục vụ 2
FMA** (thay vì 1), nên broadcast không còn là nút cổ chai — trong khi số thanh ghi
vẫn khớp 16. 4 hàng × 2 ymm = 8 acc + 2 ymm B = 10 ymm sống, thoải mái.

Kết quả (14 luồng, f32): n=512 **0.70 → 0.55 ms**, n=768 **2.00 → 1.52 ms**.
f64: n=512 **1.51 → 1.20 ms**, n=1024 **11.9 → 9.3 ms**.

Nhánh đuôi (j không chia hết 16 / i không chia hết 4) xử lý bằng vòng scalar
4 hàng một (giữ nguyên độ chính xác, `err=0`).

---

## 5. WRAPPER `list[f64]` KHÔNG COPY (commit `85cec06`)

`simd_gemm(a, b, r, n)` nhận `list[f64]` (rang buộc cú pháp DSL). Nếu
`ToArray()` + gọi + `Clear/AddRange` thì mất 2.5–2.7×. Thay bằng lấy thẳng mảng
nền:

```
Type::GetTypeFromHandle(ldtoken List<T>) → Type::GetField("_items", 36)   // NonPublic|Instance
→ FieldInfo::GetValue(obj) → castclass T[]   // mảng nền, dung lượng >= Count
```

Rồi `pin` + `calli`/P/Invoke ghi thẳng vào đó. **Bẫy đã gặp:** wrapper phải
**tự chứa toàn bộ phần pin + gọi native**; nếu gọi sang một method `Gemm<H>` khác,
JIT nội tuyến nó và phát ra con trỏ hỏng khi mảng đến từ reflection → **AV
(0xC0000005)** hoặc ghi vào hư không. Kiểm chứng bằng IL viết tay: `ldelema` +
local `pinned` **trong cùng method** thì đúng.

Guard: `ldlen >= n*n` trước khi ghi (mảng nền có thể lớn hơn `Count`).

---

## 6. KẾT QUẢ ĐO — so NumPy (scipy-openblas, OpenBLAS 0.3.34, MAX_THREADS=24)

Máy: Xeon E5-2695 v3 @2.30 GHz, 14 core/28 logical, AVX2+FMA (không AVX-512).
Số của C là best-of; NumPy là best-of-30.

| n | f32 C SIMD | f32 NumPy | tỉ số | f64 C SIMD | f64 NumPy |
|---|---|---|---|---|---|
| 128 | **0.039** | 0.122 | 3.1× | **0.055** | 0.098 |
| 192 | **0.065** | 0.155 | 2.4× | **0.104** | 0.178 |
| 256 | **0.109** | 0.180 | 1.65× | **0.196** | 0.231 |
| 384 | **0.259** | 0.294 | 1.14× | **0.497** | 0.828 |
| 512 | **0.496** | 0.811 | 1.63× | **1.03** | 1.569 |
| 768 | **1.406** | 1.836 | 1.31× | **2.89** | 3.780 |
| 1024 | **3.68** | 3.867 | 1.05× | **7.59** | 9.921 |

⇒ **Thắng NumPy ở MỌI n = 128…1024**, cả f32 lẫn f64 (1.05×–3.1×).
TokenVector benchmark (`run_benchmark.exe`, best-of-N):

```
f32mm simd n32   0.0033 ms   (~33.4× nhanh hon scalar)
f32mm simd n128  0.0608 ms
checksum: 937.174 / 6571.537  <-- khop NumPy
```

---

## 6b. HAI ĐÒN BẨY ĐỂ THẮNG Ở n LỚN

### 6b.1 Padding leading-dim panel B — đòn quyết định

Ở n=1024, C 4.55 vs NumPy 3.735. Nghi ngờ **conflict-miss L1** vì stride panel B
= `NC` = 64 (lũy thừa 2) → `bp[p*64+j]` cho các `p` khác nhau rơi vào **cùng tập**
cache (64 float = 256 byte = 4 dòng, tập lặp lại). Thêm 4 float đệm
(`GEMM_BPL = NC + 4`):

| BPL | n=1024 f32 (avg 4 lần) |
|---|---|
| 64 (không đệm) | ~4.55 |
| 72 (NC+8) | 4.274 |
| **68 (NC+4)** | **4.078** |
| 80 | 4.101 |
| 128 | 4.574 |

f64: `GEMM_BPL64 = NC64 + 2` (66) tốt nhất (7.6 vs 8.5 không đệm). **Đây là đòn
đắt nhất ở n lớn** — nhớ nguyên tắc "đừng để stride là lũy thừa 2".

### 6b.2 Chia luồng 2 chiều + hyperthread

Ban đầu (mục 3) HT **hại** vì mỗi thread đọc cả B. Chia luồng **2 chiều**
(`rows × cols`, `TKV_GEMM_COLS`): mỗi thread chỉ đọc/pack một **dải cột** của B →
working-set/thread nhỏ hơn. **Chỉ sau khi padding panel B** thì HT mới có lợi:

| cấu hình | n=1024 f32 |
|---|---|
| cols=1, 14 luồng (vật lý) | 4.26 |
| cols=2, 14 luồng | 3.91 |
| cols=2, 28 luồng (HT) | 3.90 |
| **cols=4, 28 luồng (HT)** | **3.50** |

Policy auto: `n < 512` → core vật lý, `cols=1`; `n ≥ 512` → **HT (2× vật lý)**,
`cols=4`. Pool thread tạo sẵn `tkv_nlogical()` thread (đủ cho cả HT).

> Thứ tự đúng: **padding trước, HT sau.** Bật HT khi panel B còn conflict-miss
> chỉ làm tệ thêm (đã thấy: 28 luồng > 14 luồng về độ tệ ở mục 3).

---

## 7. VIỆC CÒN DỞ

| việc | ghi chú |
|---|---|
| **A-packing** | **ĐÃ THỬ, KHÔNG GIÚP.** Pack A panel `MC×KC` làm tệ hơn (n=1024: 4.40 → 4.57) — A vốn đã liên tục theo `p`, copy thêm là lãng phí. Đã gỡ |
| **Pad cả A/C** | Chỉ panel B được pad. A đọc trực tiếp (4 dòng/lần → ít conflict); C ghi chỉ 4 dòng. Chưa thử pad (không pad được mảng gọi vào) |
| **Bỏ memset đầu** | Có thể bỏ `memset` bằng cách cho pass `pc=0` **store** thẳng thay vì RMW (tiết kiệm 1 lượt đọc+ghi C). Chưa làm — ~3% |
| **`tools/simd_kernels.py`** | Không còn (script sinh blob base64 AVX2/SSE cũ, đã mồ côi; blob vẫn chạy) |
| **Còn nhiễu** | n=1024 dao động ±0.3 ms giữa các lần. Luôn best-of nhiều lần |

---

## 8. LƯU Ý VẬN HÀNH / TÁI LẬP

**Build DLL** (trong `Release\tools\simd_native`):

```powershell
$vs = "C:\Program Files\Microsoft Visual Studio\18\Community"
cmd /c "call `"$vs\VC\Auxiliary\Build\vcvars64.bat`" >nul 2>&1 && `
  cl /nologo /O2 /arch:AVX2 /fp:fast /LD tkv_simd_native.c `
  /Fe:tkv_simd_native.dll /Fo:tkv_simd_native.obj"
Copy-Item tkv_simd_native.dll ..\..\runtime\tkv_simd_native.dll -Force
Copy-Item tkv_simd_native.dll ..\benchmark\tkv_simd_native.dll -Force   # benchmark nap DLL canh no
```

**Test kernel:**

```powershell
cmd /c "call `"...vcvars64.bat`" >nul 2>&1 && `
  cl /nologo /O2 /arch:AVX2 /fp:fast test_sgemm.c /Fe:test_sgemm.exe /Fo:test_sgemm.obj tkv_simd_native.lib"
.\test_sgemm.exe        # in err=0 cho n=32..1024 (f32+f64)
```

**Quét tile (không sửa code):**

```powershell
cl ... /DGEMM_KC=128 /DGEMM_NC=64 ...   # hoac /DGEMM_KC64 /DGEMM_MC64 /DGEMM_NC64
```

**Ép luồng để đo scaling:** `$env:TKV_GEMM_THREADS=8; $env:TKV_GEMM_MIN_N=1`.

**Benchmark TokenVector:** `Release\tools\benchmark\run_benchmark.exe`
(nhớ copy DLL mới sang `benchmark\` trước).

**Gate:** `cd Release; & tools\testkit_gate.ps1` → `PASS=125`.

**Cẩn thận đo:** nhiễu máy lớn (n=768 dao động 1.52–2.70 ms giữa các lần). Luôn
chạy 2–3 lần, lấy best-of-N. `test_sgemm.c` tự ghi lại **checksum** để phát hiện
kết quả sai (đổi kernel mà checksum lệch là fail ngay, không lọt).

---

## 9. BÀI HỌC

1. **Topology luồng > cache tile.** Đổi từ logical→physical core cho lợi ích lớn
   gấp nhiều lần mọi lần quét KC/NC/MC. Đo scaling 1→16 luồng *trước* khi đụng tile.
1b. **Đừng để stride là lũy thừa 2.** Chỉ +4 float đệm panel B cho ~10% ở n=1024
   (4.44 → 3.89) — hơn mọi lần quét KC/NC/MC cộng lại. Nhưng **thứ tự quan trọng**:
   phải pad trước rồi mới bật HT, ngược lại HT làm tệ thêm.
2. **Micro-kernel: cân nhắc cổng nạp.** NR rộng (16 f32 / 8 f64) biến broadcast A
   từ nút cổ chai thành không đáng kể → chạm đỉnh FMA. Đếm uop, đừng đoán.
3. **Reflection wrapper phải tự chứa.** Gọi native qua một method trung gian bị JIT
   nội tuyến → con trỏ hỏng. Giữ pin + P/Invoke trong **cùng** method.
4. **Luôn ghi checksum.** "Nhanh mà sai" không thể phát hiện bằng đo thời gian
   (bài học từ handoff 2026-10-14, áp dụng lại ở đây).
