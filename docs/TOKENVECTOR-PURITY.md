# Trạng thái thuần TokenVector của compiler (đo 2026-10-03)

## Đo được gì

`compiler_src/ds_gop.txt` liệt kê **125 file** là nguồn thật của `tv2s.exe`.
Đo 125 file đó:

| | Số file |
|---|---|
| Thuần TokenVector (`def` có chữ ký, 0 dòng `import`) | **6** |
| Hỗn hợp TokenVector + Python | **91** |
| Thuần Python | 25 |
| Rỗng / không có hàm | 3 |

`compiler_bootstrap/tkv_compile.tkv` tự nói trong docstring:
*"đang là Python HỢP LỆ, chạy được thật dưới CPython thật, không phải một
ngôn ngữ riêng — quy ước đặt tên `.tkv` thay vì `.py` để cắt dứt liên hệ
tên gọi với Python"*.

## `compiler_src/` là gì — không phải compiler đầy đủ

`hg_all.tkv` **không phải** compiler hoàn chỉnh. Nó là
`seed_lex.tkv` + `seed_emit.tkv` nối lại. Bằng chứng:

- **352 hàm trùng tên** giữa `hg_all.tkv` và `seed_emit.tkv`/`seed_lex.tkv`
- `KRG_CHU` nằm ở **cả hai**: `hg_all.tkv:8747` và `seed_emit.tkv:8151`
- Dòng đầu của `hg_all.tkv` ghi rõ `# seed_lex.tkv - bo tach tu...`

23.971 dòng trong `compiler_src/` là **seed** — compiler TokenVector thuần dùng
để khởi động việc hợt giống, không phải bản compile đầy đủ.

## "Điểm bất động" ≠ "thuần TokenVector"

Hai việc khác nhau, dễ nhầm:

- **Điểm bất động** (`g1.il == g2.il`) = compiler **tự tái tạo chính nó y hệt**.
  Không nói gì về việc mã nguồn đã thuần TokenVector.
- **Thuần TokenVector** = 6/125 file ở trên.

Tài liệu bàn giao 2026-09-19 ghi *"hàm được sạch 93/303"*, và chặng
`mau8 (rut gon danh sach)` chính là để **giảm** số file phải gộp.

## Đừng so `.exe`, hãy so `.il`

Đo lại trong D: — `g1.exe` và `g2.exe` **không** cùng byte:

```
g1.il   11237 KB   F31062E138AA3195D790E239
g2.il   11237 KB   F31062E138AA3195D790E239   <- giu
g1.exe   1341 KB   07262319A56E230EAA8F4691
g2.exe   1341 KB   4A43181BCF32EF0255445670   <- KHAC, va phai khac
```

`ilasm` không tắt định (MVID đổi mỗi lần ghép), nên so `.exe` sẽ **luôn**
báo khác. Đây đúng là điều tài liệu cũ đã cảnh báo.

## Tái lập được trong D:

```
tools\vong.exe
  gop 125 file
  g1 xong
  g2 xong
  IL_IDENTICAL
```

2,8 phút. `g1.exe` biên dịch và chạy đúng `tests/counter_test.tkv`.

Hash `F31062E138AA3195D790E239` của `g1.il`/`g2.il`/`tv2s.il` **trùng khớp**
với hash bàn giao ở cây E: — D: tái tạo đúng compiler gốc.

## Hướng đi

1. Port 125/125 file sang TokenVector thuần (hiện 6).
2. Khi đó viết manifest TokenVector thuần thay `ds_gop.txt`.
3. Bỏ `compiler_bootstrap/` khỏi đường chạy.
4. **Không** đưa `tools/hat_giong/*.py` vào D: — chúng là máy sinh (gộp cây
   Python, dịch Python → TokenVector, đếm hàm sạch) và đo (chạy 78 mẫu vàng).
   `tools/vong.tkv` đã làm trọn vòng bằng TokenVector; đưa Python vào là
   **thêm** phụ thuộc.