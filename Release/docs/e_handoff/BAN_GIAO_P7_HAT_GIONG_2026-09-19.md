# Bàn giao P7 / hạt giống — 2026-09-19

> Đọc file này đầu phiên sau. Nó chỉ nói về **đường tự-host P7 qua hạt giống**
> (`compiler_src/`), không thay `docs/NEXT_SESSION_HANDOFF.md` (đã cũ, 2026-08-11,
> nói về Phase 0-4 — giữ nguyên làm lịch sử).

## 1. Đang ở đâu

| Chỉ số | Đầu phiên | Cuối phiên |
|---|---|---|
| Lỗi dịch trên tập nguồn bắt buộc | 259 | **207** |
| Hàm dịch sạch | 885 / 950 | **899 / 950** |
| Mẫu trong cổng | 23 | **31** |
| Điểm bất động `v1.il == v2.il` | đạt | **đạt** (644 288 ký tự) |
| Hồi quy production | PASS 255 / FAIL 10 | **PASS 255 / FAIL 10** (cùng 10 tên) |

Commit cuối: `229a9a73`.

## 2. Công cụ (đều thuần TokenVector, KHÔNG cần Python)

```bash
tools/hat_giong/thu.exe     <goc> <thu_muc_nguon> <thu_muc_exe>   # CỔNG: 31 mẫu + 5 mốc
tools/hat_giong/lam_moi.exe <goc> <thu_muc_nguon> <thu_muc_exe>   # làm mới hạt giống tới điểm bất động
tools/hat_giong/cho_an.exe                                        # đo nhanh (22,8 s)
```

Hai thư mục **phải khác nhau** (exe tách khỏi nguồn). Sau mỗi lần sửa
`compiler_src/`: chạy `lam_moi.exe` rồi `thu.exe`. Cổng phải ĐẠT trước khi commit.

Script đo (dev, dùng CPython, chỉ để xếp hạng rào — không nằm trên đường bootstrap):
`_scratch/do.py` (xếp hạng lỗi), `_scratch/theo_file.py` (lỗi theo file),
`_scratch/chay.py` (dịch + CHẠY một file thử), `_scratch/do_dict_stmt.py` /
`_scratch/do_kieu_thuc.py` (bọc hàm lúc chạy để ĐO kiểu thật).

## 3. Phân bố rào còn lại

```
207
 147  control_flow.tkv     71%
  24  closures.tkv
   9  il_dispatch.tkv
   9  il_codegen.tkv
   6  il_core.tkv
   5  typed_dsl_parser.tkv
   6  bốn file còn lại
```

## 4. VIỆC KẾ TIẾP (đã đo, chưa làm)

Rào chính **không** phải ngôn ngữ thiếu kiểu lồng — đã đo, cả hai trình biên dịch
đều nhận `dict[str,dict[str,Sg]]` ở tham số, kiểu trả về **và trường của record**,
và `elem_ta` giữ đủ cấu trúc. Rào là **các đường suy kiểu đọc trường `dtype` phẳng**
(luôn là kiểu trong cùng) thay vì `elem_ta`. Đã vá đúng một đường (`.get`/`.pop`/
`.setdefault`, commit `229a9a73`).

Kế hoạch đề xuất, làm từng bước một, mỗi bước một lần chạy cổng:

1. Đo kiểu thật của từng trường `TkvTable` trong `Ctx`/`Registry`
   (`il_dispatch.tkv`, 23 chỗ) bằng cách bọc hàm lúc chạy — **đã làm thế cho `sig`**:
   1 586 lời gọi, 100% là `Signature`, không lần nào `None`.
2. Đổi từng trường sang kiểu thật, bắt đầu bằng `record_methods` →
   `dict[str,dict[str,Signature]]` (đã kiểm là hợp lệ ở cả hai trình biên dịch).
   `control_flow.tkv` có 27 chỗ `.get(...)` trên đúng các bảng này.
3. `Scope.vars` **chưa quyết được**: lưu `('arg', int, ta)` / `('const', str, ta)` /
   `('global', None, ta)` — ô thứ hai là `int | str | None`. Không khai được kiểu nào
   mà không sai. **Cần người dùng chốt** cách bỏ union.

Rào hạt giống thuần còn lại (rẻ hơn nhưng ít lỗi): `def` lồng **có `nonlocal`**
(19 chỗ) và `def` lồng **dùng làm giá trị** (14 chỗ) — cả hai cần lớp ô nhớ,
là việc lớn. `%` format chuỗi, `m.lastgroup`, `min/max` trên biểu thức sinh: mỗi
cái 2-5 lỗi.

## 5. LỖI CHƯA GIẢI THÍCH ĐƯỢC — đừng phí thời gian đoán lại

`ACCESS_VIOLATION` (rc 3221225477) của hạt giống, **tái lập được 100%**:

> Cùng một đầu vào, cùng một exe, chỉ đổi **độ dài đường dẫn tệp nguồn**:
> 56 ký tự chạy được, **57 / 58 / 59 đổ vỡ**, 60 trở lên lại chạy được.

Đo bằng: tạo thư mục tạm, ghi cùng một nguồn ra các tên `x.tkv`, `xx.tkv`, …,
chạy `hat_giong_seed.exe <nguon> <ra.il>`, in `returncode`.

Đã thử và **BÁC BỎ**: giả thuyết `.maxstack` khai thiếu. (Một lượt đo thấy hết vỡ
nên tôi từng kết luận "đã xác nhận" — **sai**; lượt sau vẫn vỡ đúng 57–59.)
Vẫn giữ phần tính `.maxstack` theo số token vì 256 cố định cho hàm 1 172 token
vốn đã sai về nguyên tắc, nhưng **nó không phải bản vá cho lỗi này**.

Cách né hiện tại: đặt tên tệp tạm ngắn/dài ra khỏi cửa sổ 57–59 (đã sửa trong
`_scratch/do.py`). Thư mục exe luôn tách khỏi thư mục nguồn.

## 6. Bài học phương pháp của phiên này

- **Cổng phải CHẠY chương trình, không chỉ đếm dòng IL.** Trường kiểu container
  của record từng dịch sạch 753 dòng IL rồi ném `NullReferenceException` —
  hạt giống không khởi tạo rỗng trong `.ctor` như trình biên dịch thật.
- **Hoãn khai báo phải CÓ CHỌN LỌC hoặc có quyền ghi đè theo chủ.** Hoãn hết mọi
  phép gán mà ai cũng ghi đè được thì phép gán *cuối* thắng — sai với mọi biến
  gán lại bằng kiểu khác. Có quyền theo chủ (chỉ mục hoãn nào tạo ra ô đó mới
  sửa được nó) thì hoãn hết lại đúng **và** tốt hơn.
- **Bộ suy kiểu và bộ phát mã phải dùng chung một vị từ.** Cho `.get` trả kiểu
  thật ở mọi trường hợp làm lỗi nhảy 214 → 794 (bảng handle mờ có kiểu giá trị là
  lớp không ai đăng ký). Giới hạn lại: chỉ vô hướng/container, và **cả hai bên
  dùng chung `kieu_biet()`**.
- **Pragma dạng ghi chú cuối dòng (`f()  # __tkv_cpython_only__`) KHÔNG được thực
  thi** — chỉ decorator mới có. Đừng dùng nó làm luận cứ.
