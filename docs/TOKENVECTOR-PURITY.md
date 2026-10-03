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

## Hướng đi

1. Sửa `tv2s` cho nhận hằng âm ở cấp module — một lỗi nhỏ nhưng nó chặn seed.
2. Port 125 file nguồn sang TokenVector thuần (hiện 6/125).
3. Khi đủ, viết manifest TokenVector thuần thay `ds_gop.txt`.
4. Bỏ `compiler_bootstrap/` khỏi đường chạy; `compiler_src/` seed thành lịch sử.
5. **Không** đưa `tools/hat_giong/*.py` vào D: — chúng là máy sinh (gộp cây
   Python, dịch Python → TokenVector, đếm hàm sạch) và đo (78 mẫu vàng).
   `tools/vong.tkv` đã làm trọn vòng bằng TokenVector.