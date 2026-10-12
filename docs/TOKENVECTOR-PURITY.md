# Trạng thái thuần TokenVector của compiler

Đo ngày 2026-10-03. **Số liệu này đính chính một nhận định sai đã viết trước đây**
rằng `compiler_src/` (23.971 dòng) là "compiler TokenVector thuần".

## Sự thật: 23.915/23.971 dòng KHÔNG được dựng

`compiler_src/ds_gop.txt` là manifest 125 file dựng ra `tv2s.exe`.
Trong `compiler_src/*.tkv` chỉ **một** file nằm trong manifest:

| File | Dòng | Trong bản dựng? |
|---|---|---|
| `tkvc_main.tkv` | 56 | **CÓ** |
| `hg_all.tkv` | 11.824 | không |
| `seed_emit.tkv` | 11.166 | không |
| `seed_lex.tkv` | 692 | không |
| `seed_main.tkv` | 129 | không |
| `codegen_cil.tkv` | 19 | không |
| `probe_lex.tkv` | 13 | không |
| `lexer.tkv` | 72 | không |

⇒ Bản dựng bỏ qua **23.915 dòng = 99,8%** của `compiler_src/`.
Và 56 dòng được dùng đó chỉ là **bọc CLI**: gọi `compile_tkv_cli(nguon, ra, vao)`,
bắt `CliError` / `TranspileError` / `Exception`. Không có logic biên dịch nào.

## Seed có bao nhiêu hàm

| | Số hàm |
|---|---|
| `seed_lex.tkv` | 32 |
| `seed_emit.tkv` | 318 |
| **Tổng** | **350** (0 trùng tên) |

`hg_all.tkv` chính là `seed_lex.tkv` + `seed_emit.tkv` nối lại — bằng chứng:
**352 hàm trùng tên**, và `KRG_CHU` nằm ở cả `hg_all.tkv:8747` lẫn
`seed_emit.tkv:8151`.

## Seed KHÔNG phải bản port của compiler đầy đủ

| | |
|---|---|
| Hàm của seed | 350 |
| Hàm của compiler đầy đủ (125 file) | 1.841 (1.914 định nghĩa) |
| **Hàm seed trùng tên với compiler đầy đủ** | **3** |

347/350 hàm của seed **không tồn tại** trong compiler đầy đủ. Seed là một
compiler viết riêng, kiến trúc độc lập — không phải "đã port được 93/303 hàm"
như tài liệu 2026-09-19 ghi.

## Seed không biên dịch được bằng `tv2s`

Hai chặn, đều tìm ra bằng thử nghiệm:

**1. Hằng số âm bị từ chối ở cấp module.** File tối giản:

```
X: "i32" = -1     ->  bien module-level 'X': gia tri khoi tao phai la 1 hang so/chuoi don gian
X: "i32" = 0 - 1  ->  loi giong het
```

Vì vậy `seed_emit.tkv` cố tình viết `KRG_CHU: "i32" = 0 - 1` (dòng 8151) và
`LG_HIEN: "i32" = 0 - 1` (dòng 8625) để né chính giới hạn của compiler.

**2.** Sau khi vá, gặp: `'list' khong phai bien da khai bao va cung khong phai
1 extern-class da khai qua __tkv_extern_class__`.

## "Điểm bất động" ≠ "thuần TokenVector"

- **Điểm bất động** (`g1.il == g2.il`) = compiler tự tái tạo chính nó y hệt.
- **Thuần TokenVector** = bao nhiêu phần trăm mã nguồn không phải Python.

Đo 125 file nguồn thật:

| | Số file |
|---|---|
| Thuần TokenVector (`def` có chữ ký, 0 dòng `import`) | **6** |
| Hỗn hợp TokenVector + Python | **91** |
| Thuần Python | **25** |

`compiler_bootstrap/tkv_compile.tkv` tự nói trong docstring: *"đang là Python
HỢP LỆ, chạy được thật dưới CPython thật... quy ước đặt tên `.tkv` thay vì
`.py` để cắt dứt liên hệ tên gọi với Python"*.

## Đừng so `.exe`, hãy so `.il`

```
g1.il   11237 KB   F31062E138AA3195D790E239
g2.il   11237 KB   F31062E138AA3195D790E239   <- giữ
g1.exe   1341 KB   07262319A56E230EAA8F4691
g2.exe   1341 KB   4A43181BCF32EF0255445670   <- khác, và phải khác
```

`ilasm` không tắt định (MVID đổi mỗi lần ghép) nên so `.exe` **luôn** báo khác.

## Tái lập trong D:

```
tools\vong.exe -> gop 125 file / g1 xong / g2 xong / IL_IDENTICAL   (2,8 phút)
```

`g1.il`/`g2.il`/`tv2s.il` cùng SHA-256 `F31062E138AA3195D790E239` — trùng hash
bàn giao ở cây E:.

## Đo bằng probe trực tiếp: compiler ĐÃ đăng ký đầy đủ

Đo đúng theo tiêu chí *"TokenVector chấp nhận và biên dịch được"* — **gọi thẳng
`dist\tkvc-tv.exe`**, không tin tài liệu. Kết quả: `tools\dang_ky_gate.py`.

```
132 file / 2090 hàm   (đo 2026-10-12, sau khi xoá khối `__tkv_chi_cpython__`)
A. có -> "kieu"                     1263  (60,5%)
B. void (thiếu chữ ký, chỉ return)   800  (38,3%)   bỏ qua 27 hàm @__tkv_cpython_only__
   ------------------------------------------------------------------
A + B  ĐÃ ĐĂNG KÝ ĐẦY ĐỦ            2063  (98,7%)
VI PHAM: 0        thiếu chữ ký tham số: 0
```

#### ⚠ Con số này KHÔNG đo được "tính năng dùng được" (2026-10-04)

`97,4%` đo **chữ ký đăng ký có khớp giữa hai bản hay không** — nó
KHÔNG đo tính năng có chạy được trên `dist\tkvc-tv.exe` hay không. Hai
sự thật đo được, mâu thuẫn với cách đọc dễ dàng của con số trên:

1. **23 module `il_features` chỉ có ở `compiler/il_features/` (bootstrap
   Python), thiếu hoàn toàn ở `compiler_bootstrap/compiler/il_features/`
   (đường TokenVector).** 119 vs 105 module. Gồm `f32buf_type.tkv`,
   `nativebuf.tkv`, `vector4_type.tkv`, `stdlib_pathlib.tkv`,
   `iter_next.tkv`, `int_narrow.tkv`, `call_star_args.tkv`.
2. **Gate chạy nhầm compiler.** `tools\testkit_gate.ps1`,
   `tools\parity_probe\run.ps1`, `tools\ext_smoke.ps1` mặc định dùng
   `dist\tkvc.exe` (bootstrap Python), KHÔNG phải `dist\tkvc-tv.exe`.
   Nên 118/118 và 119/119 **không chứng minh điều gì về sản phẩm**.

Đo lại trên chính sản phẩm (`testkit_gate.ps1` nay đã đổi mặc định sang
`tkvc-tv.exe`):

```
tkvc.exe    (bootstrap) : PASS 118/118, NEG 31/31
tkvc-tv.exe (SẢN PHẨM)  : PASS  74/118, NEG  0/31
```

14/44 lỗi còn lại truy veo 7 module chưa port. Phan cum day du:
`tools\testkit_cluster.ps1`. **Dung con so 97,4% de ket luan "compiler tu host
da hoan chinh" la sai.**

### Probe chỉ ra những gì (đừng đoán)

| Construct | `tv2s` |
|---|---|
| f-string, `f"{n:05d}"`, `f"{v:.2f}"`, `.format()` | chấp nhận |
| tuple, tuple-unpack, `raise`, biểu thức 3 nhánh | chấp nhận |
| dict literal, list/dict/set comprehension | chấp nhận |
| `try/except`, `lambda`, `nonlocal`, `del`, `with`, `assert` | chấp nhận |
| `class`/record, `global` | chấp nhận |
| **generator** (`yield`) | chấp nhận **nếu** `-> "list[dtype]"` + có ít nhất 1 `yield` |
| `X: "i32" = -1` (hằng âm cấp module) | **từ chối** |
| `X: "i32" = 1 + 1` (biểu thức cấp module) | **từ chối** |

### Co che CPython con lai trong compiler

**2026-10-12: khoi `if __tkv_chi_cpython__:` đã bị XOA khỏi nguồn compiler.**

Trước đó compiler bỏ qua 2 loại cấu trúc CPython:

| Cấu trúc | Trạng thái |
|---|---|
| `if __tkv_chi_cpython__:` | **ĐÃ XOA** — mọi khối và cả cơ chế nhận diện (`_la_khoi_chi_cpython`) trong `tkv_compile.tkv` |
| `@__tkv_cpython_only__` | còn — bỏ qua **hàm** (27 hàm) |

Lý do xoá: những khối đó chỉ tồn tại để file `.tkv` chạy được trên **hai**
thế giới (TokenVector biên dịch, CPython chạy trực tiếp để đối chiếu). Khi
TokenVector đã tự host, phía CPython đã tách hẳn sang repo
`TokenVector.CompilerPy` (nơi có bản `tkv_compile.tkv` riêng, **không** cần cơ
chế bỏ qua vì dưới CPython cờ chỉ là biến `True` và khối chạy bình thường).
Giữ lại chỉ là Python thừa trong nguồn compiler mà không ai dùng.

Hệ quả: `dist\tkvc-tv.exe` **không còn khối `if __tkv_chi_cpython__` nào**, và
số hàm không nằm trên đường TokenVector giảm từ 49 xuống còn 27 (toàn bộ là
`@__tkv_cpython_only__`).

### Ba lỗi analyzer đã mắc phải (để người sau không lặp lại)

1. Dùng allow-list của **seed** (`cong_cu_phap.py`) làm chuẩn — sai; seed có
   350 hàm, envelope tối giảu, không đại diện cho compiler 1.911 hàm.
   → Chạy `cong_cu_phap.py` cho kết quả 580/1911 "sạch", trong khi thật là 1.862.
2. Bọc thân probe trong `try/except` — mà `try:` cũng bị từ chối ở vị trí đó,
   nên **22/24 probe sai thành "từ chối"**. Bài học: probe phải tối giản, một
   construct một file.
3. `ast.walk` **vẫn đi xuống cây của hàm lồng** dù đã `continue` trên nút
   `FunctionDef` — quy `return` của hàm lồng cho hàm ngoài, báo động 2 vi phạm
   giả. Phải tự đệ quy, bỏ cả cây. `tools\dang_ky_gate.py` có tự kiểm 4 ca
   để chặt lỗi này.

## Sai ở đâu khi đo bằng văn bản thay vì probe

Bảng đầu của tài liệu này từng ghi "6/125 file thuần TokenVector". Con số đó
trả lời câu hỏi *"file nào không có dòng `import`"* — không phải câu hỏi của bạn.
Theo đúng tiêu chí của bạn thì kết luận là: **không còn hàm nào chưa đăng ký.**

## Hướng đi còn lại

1. Seed (`hg_all`/`seed_emit`/`seed_lex`, 23.915 dòng) **không dùng trong bản
   dựng**. Cho `tv2s` nhận hằng âm và `list` ở cấp module thì biên dịch được
   seed → seed thành nguồn dựng thứ hai, độc lập với `compiler_bootstrap/`.
2. Gộp `compiler_src/ds_gop.txt` vào `compiler_bootstrap/ds_gop.txt` để có
   **một** manifest duy nhất.
3. **Không** đưa `tools/hat_giong/*.py` vào D: — chúng là máy sinh (gộp cây
   Python, dịch Python → TokenVector, đếm hàm sạch) và đo (78 mẫu vàng).
   `tools/vong.tkv` đã làm trọn vòng bằng TokenVector.