# TokenVector — lỗi/thiếu sót phát hiện ngày 2026-08-04

> **Cập nhật 2026-08-06**: mục 9-13 cũ + toàn bộ B1-B6 trong `BUGS_TODO.md`
> đã sửa và commit (xem đầu file đó). Còn mở, CHƯA ĐỘNG TỚI: mục **1**
> (dist/tkvc.exe regress), **3** (thiếu duyệt thư mục đệ quy), **6**
> (`dict[str,i32]` tham số → segfault, ưu tiên cao nhất vì "nghiêm trọng"
> + chưa điều tra), **7** (nối chuỗi trong vòng lặp chậm ~68x, hiệu năng
> không phải đúng/sai), **8** (viết tài liệu, không phải bug).
>
> **Cập nhật 2026-08-10**: mục **2** (slicing không clamp) **KHÔNG CÒN TÁI
> HIỆN** — test lại `s[0:5]` với `s="ab"` (`dist/tkvc.exe` hiện tại) trả
> về `"ab"` đúng như Python, không còn `ArgumentOutOfRangeException`. Đã
> được sửa ở đâu đó giữa 2026-08-04 và nay, không rõ commit cụ thể — đóng
> mục này, không cần điều tra thêm trừ khi tái hiện lại.

> **Cần biết PHẢI LÀM GÌ thì đọc `BUGS_TODO.md`** — danh sách việc ngắn, đã
> xác nhận tái hiện, xếp theo mức thiệt hại. File này giữ phần phân tích và
> truy nguyên: đọc khi cần hiểu *vì sao*.

Phát hiện trong lúc viết `tools/impgraph.tkv` (công cụ thật, không phải test).
Xếp theo mức nghiêm trọng.

---

## 1. `dist/tkvc.exe` bị REGRESS so với compiler nguồn — NGHIÊM TRỌNG

`dist/tkvc.exe` từ chối biên dịch **chính `tools/codestat.tkv`** — công cụ đã
ship, đã có `.exe` và có test trong `test/verify/codestat_test.py`.

```
dist\tkvc.exe build tools\codestat.tkv
[tkv] Loi: Chi ho tro dinh nghia ham/class-record top-level ...;
      gap Assign o dong 20
```
(dòng 20 = `TAB_WIDTH = 4`)

Cùng file, compiler nguồn dịch tốt:
```
python tkv.py build tools\codestat.tkv     ->  OK
```

Hai tính năng `dist/tkvc.exe` không có mà `compiler/` có:
- hằng số cấp module (`TAB_WIDTH = 4`)
- docstring bên trong hàm (cả 1 dòng lẫn nhiều dòng)

**Hệ quả:** bộ 101 test đang xanh vì chạy qua `compiler/`, không qua
`dist/tkvc.exe`. Người dùng thật chỉ có `tkvc.exe` → gặp lỗi mà test không bắt.

**Cần làm:** build lại `dist/tkvc.exe` từ `compiler/` hiện tại
(`powershell -File build_tkvc.ps1`), rồi thêm 1 test smoke **chạy qua
`dist/tkvc.exe`** để chặn regress kiểu này (đây đúng là "false-green test").

---

## 2. [ĐÃ SỬA — không còn tái hiện 2026-08-10] Slicing không clamp như Python

```python
s = "ab"
s[0:3]      # Python  -> "ab"   (tự cắt ngắn)
            # TokenVector -> System.ArgumentOutOfRangeException (TRƯỚC ĐÂY)
```
Trace từng gặp:
```
System.ArgumentOutOfRangeException: Index and length must refer to a
location within the string.  at System.String.Substring(Int32, Int32)
```

Test lại 2026-08-10 qua `release/3.code/dist/tkvc.exe`: `s[0:5]` với
`s="ab"` trả về `"ab"` đúng, không crash — đã được clamp đúng ở đâu đó
giữa 2026-08-04 và nay (không rõ commit cụ thể sửa nó).

**Cần làm:** clamp `start`/`stop` về `[0, len]` trước khi gọi `Substring`.

---

## 3. Thiếu duyệt thư mục đệ quy — THIẾU TÍNH NĂNG

`os_list_files(path)` chỉ liệt kê 1 cấp (`Directory.GetFiles(string)`).
Không có `os_list_dirs` → **không thể duyệt cây thư mục bằng .tkv thuần**.

Mọi công cụ quét mã nguồn toàn repo đều vướng. `impgraph.tkv` phải nhận
manifest dựng sẵn từ ngoài.

**Cần làm:** thêm `os_list_files_rec(path)` dùng
`Directory.GetFiles(path, "*", SearchOption.AllDirectories)` — đã thử
nguyên mẫu, IL chỉ 4 dòng, hợp khuôn plug-and-play của
`il_features/stdlib_os.py`. Hoặc `os_list_dirs(path)` để tự đệ quy.

---

## 4. Gọi method trên KẾT QUẢ của lời gọi hàm làm mất suy luận kiểu — SAI

```python
def tbl() -> "str":
    return "abc"

def f(ch: "str") -> "i32":
    if tbl().find(ch) >= 0:   # -> KeyError: 'str' trong _expr_num
        return 1
    return 0
```
Compiler coi `tbl().find(ch)` là `str` rồi đem so sánh với số → nổ ở
`il_codegen.py:_expr_num`, `IL_LDC_OP['str']`.

Cách né: gán ra biến trung gian trước (`t = tbl()` rồi `t.find(ch)`).

Ngoài lỗi suy luận, thông báo `KeyError: 'str'` là traceback Python trần,
không phải thông báo lỗi cho người dùng — nên đổi thành `SyntaxError` có
chỉ rõ dòng.

---

## 5. Không gọi được method trên BIỂU THỨC — chỉ trên biến

```python
lines = read_file(p).split("\n")        # loi parse
step  = ("a" + b).join(parts)           # loi parse
```
Phải gán ra biến trung gian trước. Thông báo lỗi ở đây **tốt** (nói thẳng
"gán biểu thức ra 1 biến trước"), khác với mục 4.

**Đính chính:** bản ghi trước của tài liệu này nói `.replace()` chưa có —
**sai**. Chính thông báo lỗi trên liệt kê đủ: `capitalize, endswith, find,
join, lower, lstrip, replace, rstrip, startswith, strip, upper`.
`.replace()` **có**, chỉ là `USAGE_GUIDE.md` không liệt kê nó. Cần bổ sung
vào tài liệu — thiếu sót tài liệu khiến người dùng tự viết lại vòng lặp ký
tự không cần thiết (đã xảy ra: `norm_slashes` trong `impgraph.tkv`).

---

## 6. Truyền `dict[str,i32]` làm THAM SỐ hàm → segfault — NGHIÊM TRỌNG

Tái hiện tối thiểu (7 dòng):
```python
def sc(counts: "dict[str,i32]") -> "i32":
    counts["a"] = 5
    return len(counts)

def r(a: "str") -> "str":
    counts = {}
    return str(sc(counts))
```
Biên dịch **thành công**, chạy → `Segmentation fault` (exit 139).

`dict[str,str]` làm tham số thì bình thường. Nghi vấn: `{}` ở phía gọi
luôn sinh `Dictionary<string,string>`, không theo annotation của hàm nhận,
nên hàm nhận ghi `int` vào dict `string` → hỏng bộ nhớ.

Nguy hiểm nhất trong danh sách này: **không có lỗi biên dịch, không có
exception .NET** — chỉ chết im lặng. Mọi bộ đếm `dict[str,i32]` truyền qua
hàm đều dính.

Cách né tạm: lưu số dưới dạng chuỗi, `dict[str,str]` (xem `scan_doc` trong
`tools/graphreview.tkv`).

---

## 7. Dồn chuỗi trong vòng lặp chậm gấp ~68 lần — HIỆU NĂNG, ĐÁNG CHÚ Ý NHẤT

Đo trên dữ liệu thật (874 file, `tools/graphstale.tkv`):

| Cách viết | Thời gian |
|---|---|
| `out = out + fp_line(rel) + "\n"` trong `for` | **75.008 ms** |
| `acc.append(...)` rồi `"\n".join(acc)` một lần | **1.098 ms** |

**68×**, cùng kết quả byte-for-byte. Đã áp dụng cho cả 4 công cụ:
`callgraph` từ ~50s xuống **7,4s**; toàn bộ pipeline 4 bước còn **12,2s**.

Điều đáng nói: hai vi-benchmark 874 vòng lặp *không* lộ ra khác biệt này
(0,64s so với 0,31s). Nó chỉ bùng lên khi chuỗi tích luỹ đủ lớn — dấu hiệu
điển hình của O(n²): mỗi lần `+` cấp phát và copy lại toàn bộ chuỗi.

Với một dự án đặt mục tiêu **nhanh hơn Python**, đây là chỗ đáng sửa nhất
trong danh sách: CPython có tối ưu riêng cho `str += ` (mở rộng tại chỗ khi
refcount = 1), TokenVector thì chưa. Hướng sửa: dựng `StringBuilder` của
.NET khi phát hiện mẫu `x = x + ...` trong thân vòng lặp.

Cho đến khi sửa: **không bao giờ dồn chuỗi trong vòng lặp**, luôn
`list.append` + `join`.

---

## 8. `write_file` là lệnh, không phải biểu thức — CẦN GHI RÕ TRONG TÀI LIỆU

```python
write_file(p, c)        # OK
ok = write_file(p, c)   # LOI: "ham 'write_file' khong ton tai"
```
Thông báo lỗi gây hiểu nhầm (nói hàm không tồn tại, thực ra là không dùng
được ở vị trí biểu thức). `USAGE_GUIDE.md` mục "File I/O" chưa nói điều này.

**Cần làm:** sửa thông báo lỗi cho đúng bản chất + ghi vào USAGE_GUIDE.

---

# Đợt 2 — phát hiện khi viết `pytok` + `typegraph` (cùng ngày)

Năm lỗi dưới đây tìm được khi viết hai công cụ thật bằng TokenVector.
**Bốn trong năm là sai âm thầm**: biên dịch thành công, chạy không báo gì,
chỉ cho kết quả sai. Nếu không đối chiếu với chính file `.tkv` đó chạy bằng
CPython thì không cách nào biết.

## 9. `or` giữa hai so sánh chuỗi LUÔN cho sai — NGHIÊM TRỌNG NHẤT

```python
if w == "def" or w == "class":     # binary: KHÔNG BAO GIỜ đúng
    ...
```
Chạy bằng CPython: đúng. Biên dịch rồi chạy: điều kiện luôn sai, im lặng.

Hậu quả thật: bảng định nghĩa của `typegraph` rỗng sạch → 0 cạnh `calls`.
Mất gần một giờ truy vết vì mọi thứ khác đều "trông bình thường".

**Cách né:** tách thành nhiều `if` riêng, dùng biến cờ.
**Cần sửa:** `compile_boolop` cho toán hạng kiểu `str`.

## 10. Hàm từ 9 THAM SỐ trở lên sinh IL hỏng

Biên dịch báo thành công; lúc chạy ném `InvalidProgramException`. Đo được:
8 tham số chạy tốt, 9 tham số hỏng.

**Cách né:** gộp các bảng tra cứu vào một `dict` với tiền tố khoá.

## 11. Gọi hàm lồng trong `str(...)` bên trong biểu thức nối chuỗi

```python
return "a=" + str(f(x)) + " b=" + str(f(y))   # sai giá trị + dính rác
a = f(x)                                       # đúng
b = f(y)
return "a=" + str(a) + " b=" + str(b)
```
Kết quả quan sát được: giá trị sai **và** chuỗi có ký tự thừa (`if=0)`).

## 12. `else` lồng sau một chuỗi `if/elif` bị bỏ qua

Nhánh `else` ngoài cùng không bao giờ chạy trong binary. Đo được: 18 cạnh
dưới CPython so với 6 cạnh của binary trên cùng dữ liệu.

**Cách né:** viết hai `if` với điều kiện bù nhau thay cho `if/else`.

## 13. Method gọi trên BIỂU THỨC (đã biết, vẫn vấp)

```python
if kw_blob().find(x) >= 0:    # KeyError: 'str' lúc biên dịch
blob = kw_blob()              # đúng
if blob.find(x) >= 0:
```
Đây là mục 1 của đợt trước ở dạng khác. Thông báo lỗi (`KeyError: 'str'`
từ `IL_LDC_OP[dtype]`) không hề gợi ý nguyên nhân thật.

---

## Ưu tiên sửa, theo mức thiệt hại thực tế

1. **Mục 9** (`or` chuỗi) — sai âm thầm, dễ gặp nhất, hậu quả nặng nhất.
2. **Mục 12** (`else` lồng) — sai âm thầm.
3. **Mục 11** (gọi hàm trong nối chuỗi) — sai âm thầm.
4. **Mục 10** (≥ 9 tham số) — ít nhất còn crash to, không giả vờ chạy đúng.
5. **Mục 13** — chỉ là bất tiện, biên dịch chặn ngay.


---

# Truy nguyên 2026-08-04 (phiên sau): mục 9, 11, 12 là MỘT lỗi, không phải ba

Nguyên nhân thật của mục 9 **không nằm ở `compile_boolop`**. IL sinh ra cho
`if w == "def" or w == "class":` là:

```
ldstr "de("        <-- đáng ra là "def"
...
ldstr ")class"     <-- đáng ra là "class"
```

Chuỗi bị **viết lại từ trước khi parse**. Bộ tiền xử lý f-string dùng regex
`f"([^"]*)"` trên cả dòng, nên nó khớp `f" or w == "` — chữ `f` ở đây là **ký
tự cuối của chuỗi `"def"`**, không phải tiền tố f-string. Điều kiện thành
luôn sai, không báo gì.

Vì sao bẫy này dễ gặp đúng ở công cụ phân tích Python: các từ khoá hay so
sánh nhất — `def`, `elif`, `self`, `if` — **đều kết thúc bằng chữ `f`**.

Kiểm lại bằng chương trình tái hiện, sau khi sửa bộ quét f-string:

| Mục | Trạng thái |
|---|---|
| 9 — `or` giữa hai so sánh chuỗi | nguyên nhân là f-string, **đã sửa** |
| 12 — `else` lồng sau `if/elif` | **không tái hiện được**; dạng thật đã gặp là `if w == "class" ... elif w == "def"`, tức cùng lỗi mục 9 |
| 11 — gọi hàm lồng trong `str(...)` | **không tái hiện được**; ký tự rác `if=0)` đúng dạng chuỗi bị f-string viết lại |
| 10 — hàm ≥ 9 tham số | nguyên nhân là `.maxstack` hằng số 8, **đã sửa** |
| 13 — method gọi trên biểu thức | **vẫn còn**, chặn ngay lúc biên dịch (`KeyError: 'str'`) |

Bài học: ba mục trong danh sách này là cùng một lỗi được ghi ba lần dưới ba
triệu chứng. Khi nhiều lỗi "sai âm thầm" cùng xuất hiện quanh chuỗi ký tự,
hãy **đọc IL sinh ra** trước khi đi tìm lỗi trong codegen — ở đây IL nói ra
nguyên nhân trong ba mươi giây, còn suy luận từ triệu chứng thì dẫn nhầm
sang `compile_boolop` và `compile_if`.

## Chưa áp dụng — để phiên TokenVector làm

Hai sửa đổi dưới đây **đã kiểm chứng nhưng KHÔNG commit**: phiên tìm ra chúng
là phiên làm CodeGraph, không phải phiên TokenVector. Bản vá đầy đủ kèm hai
file test nằm ở `docs/patches/fstring-maxstack-2026-08-04.patch`.

- `compiler/il_features/fstring.py` — quét có trạng thái chuỗi thay cho
  regex; chỉ coi `f"` là f-string khi đang **ngoài mọi chuỗi** và ký tự
  ngay trước không phải ký tự định danh.
- `compiler/il_codegen.py` — `_max_stack_for(body)`: `.maxstack` tính từ số
  tham số lớn nhất trong các lệnh `call`/`newobj` của thân hàm, cộng biên 8.

Test kèm theo trong bản vá: `test/verify/parity_traps_test.py` +
`test/sample_parity_traps.tkv`, đối chiếu CPython chạy chính file đó, 18/18
mẫu. Đã đối chứng bằng cách khôi phục hành vi cũ: test bắt được 6/18 sai lệch.

**Chưa chạy bộ test đầy đủ** (~130 file, mất hơn 20 phút). Bắt buộc chạy sạch
trước khi commit bản vá — `.maxstack` và tiền xử lý f-string đụng tới **mọi**
chương trình biên dịch, không chỉ hai bẫy trên.

## Còn lại cho phiên sau

- **Mục 13** (method gọi trên biểu thức) — chưa sửa. Chặn lúc biên dịch nên
  không nguy hiểm, chỉ bất tiện; cách né là gán ra biến trung gian.
- **`x not in <set>`** không parse được (`SyntaxError: còn thừa token 'not'`)
  — gặp khi viết `domain.tkv`, chưa có trong danh sách trên. Cách né: dùng
  `dict` rồi so `len(d.get(k, "")) == 0`. Với `dict` thì `not in` chạy được,
  chỉ `set` là hỏng.
- **`d[f(a, b)] = v` không parse được** — bộ tách chỉ số cắt tại dấu phẩy
  **bên trong lời gọi hàm** (`idx_str.split(',')`), rồi báo `ky vong ')',
  gap None` — thông báo không gợi ý gì về nguyên nhân. Gặp khi viết
  `impact.tkv`. Cách né: gán ra biến trung gian trước khi làm khoá.
- **`.rfind` chưa có** (chỉ có `.find`) — tự quét lấy vị trí cuối.
- **`for k in dict`** ném `ArgumentNullException` trên dữ liệu thật — đã biết
  từ trước, cách né là gom danh sách khoá ngay lúc thêm.
