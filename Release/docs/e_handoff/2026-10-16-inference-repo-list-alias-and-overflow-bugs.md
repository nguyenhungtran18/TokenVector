# 2026-10-16 - TokenVector.Inference: gan list vao field lam sai gia tri + checked int

Trang thai: `inference_tests.tkv` **26/26 PASS**, `gap_tests.tkv` **16/16 PASS**,
`quickstart.tkv` OK (Y[0]=2.25), `compare_rivals.tkv` chay het
(`ok=500 err=0`) - tat ca build + chay duoc voi `Release/dist/tkvc-tv.exe`
hien tai. Xem tiep note `2026-10-16-inference-repo-record-container-type.md`.

Muc do tin cay (cap nhat 2026-10-17 sau khi compiler moi ve):

| muc           | hien trang                                              |
|---------------|---------------------------------------------------------|
| BUG 1         | XAC NHAN - repro doc lap, lap lai 100%; **compiler moi van con** |
| BUG 2         | XAC NHAN - khac biet hanh nghi co y; **compiler moi van con** |
| BUG 3 / 4     | CHUA TAI HIEN doc lap - co the la he qua cua BUG 1, xem   |
|               | note lien quan                                           |

Thong bao chinh thuc cua phia compiler:
`D:\TokenVector.Inference\COMPILER-NOTES-2026-10-16.md` (125/125 test, build
IL_IDENTICAL). Note nay bo sung **chi tiet vi tri sua trong source compiler**
va **do chinh chu** cho nhung diem note chinh thuc chua noi.

Phia TokenVector.Inference da giu workaround trong code va ghi chu tai choi
dung. Repro cua BUG 1 nam ngay trong file note nay (chay `tkvc repro.tkv
repro.exe`); khong co thu muc `repro/` rieng.


## BUG 1 (nghiem trong) - gan list vao field/ bien khac lam SAI GIA TRI phan tu

Do dai dung, gia tri sai.

```tkv
class Box:
    _ok: "i64"
    v: 'list[f32]'
    def __init__(self, v: 'list[f32]'):
        self.v = v

def main() -> 'i32':
    _src = []
    _src.append(1.0)
    _src.append(2.0)
    _src.append(3.0)
    _o = Box(_src)
    # len(_o.v) == 3  -> dung
    # _o.v[0] khac 1.0, _o.v[1] khac 2.0, _o.v[2] khac 3.0 -> SAI
    return 0
```

Cac bien theo doi:

| cach gan                              | ket qua          |
|---------------------------------------|------------------|
| `_loc = _src` (bien local -> bien)     | DUNG             |
| `for e in _src: _copy.append(e)`       | DUNG             |
| `_o.v = _src` (local -> field)         | **SAI**          |
| `Box(_src)` (tham so -> field)         | **SAI**          |
| `Box(_d)` voi `_d` list tao trong ham khac | DUNG           |
| `self.fmap[off] = fresh` (dict field)  | DUNG (test rieng)|

**GHI CHINH XAC (2026-10-17, kiem chung lai bang compiler moi):** nguyen gan
khong phai "list dua vao field" ma la **khong khop kieu container tai duong
goi `.ctor`/method**: `_src = []` roi `.append(1.0)` se duoc suy ra la
`list[f64]`, con tham so la `list[f32]` -> compiler KHONG convert, KHONG bao
loi, va ket qua la rac. Do do:
- `Box(_d)` "tao trong ham khac" DUNG chi vi `_nd_f32()`/`nd_f32()` tra ve
  `list[f32]` that, dung kieu tham so.
- `self.fmap[off] = fresh` DUNG vi `fresh` da la `list[f32]`.

Workaround phia repo: **copy tung phan tu** (`for e in src: dst.append(e)`) khi
ghep list, va truyen list dung kieu vao `.ctor`.

Workaround thu hai trong thong bao chinh thuc ("khai bao bien dung kieu",
`_src: 'list[f32]'`) **CHUA BIEN DICH DUOC** tren compiler hien tai:
`il_codegen: khong dich duoc dong: "_a: 'list[f32]' = []"` (va ca khi
gan tu bien khac). Nen chi dung duoc copy phan tu.

Luu y khi viet repro: **phai kiem ca 2 chieu doc va ghi** - chi doc `len()` se
bo loi sot vi do dai van dung.


## BUG 2 - phep nhan/c cong i64 dung CHECKED arithmetic

Khong co wrap-around nen LCG 64-bit kinh dien nem OverflowException truoc khi
`& 0xFFFFFFFFFFFFFFFF` kip mask.

```tkv
s = (s * 6364136223846793005 + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
# -> System.OverflowException
```

Workaround: bo sang LCG 31-bit (`s = (s * 1103515245 + 12345) & 0x7FFFFFFF`),
san pham < 2^61, luon vua i64.

Neu thu vien can wrap 64-bit, nen co ham `mul_wrap_u64`/`add_wrap_u64` rieng
hoac co khoa unchecked - hien tai khong co cach nao trong nguon `.tkv`.


## BUG 3 (CHUA TAI HIEN) - goi ham long nhau trong danh sach tham so `.ctor`

Quan sat duoc 2 lan trong repo:

```tkv
def lora_linear_create(w, b, ...) -> 'LoRALinear':
    l = LoRALinear(1, lin_head(w, b, m, n, k), m, n, k, rank, alpha)
    # -> System.NullReferenceException trong LinHead.__init__ (self.w == null)
```

NHUNG: khong tai lap duoc khi tach nho - goi ham long nhau trong tham so `.ctor`
trong file doc lap **van chay dung**:

```tkv
class Inner:
    _ok: "i64"
    v: "i64"
    def __init__(self, v: "i64"):
        self.v = v

class Outer:
    _ok: "i64"
    inner: 'Inner'
    tag: "i64"
    def __init__(self, inner: 'Inner', tag: "i64"):
        self.inner = inner
        self.tag = tag

def make_inner(v: "i64") -> 'Inner':
    return Inner(v)

def direct(x: "i64") -> 'Outer':
    return Outer(make_inner(x), 7)      # -> inner.v=5, tag=7  (DUNG)
```

Khac biet giua hai truong hop la chuoi `w`/`b` la **list**, va cung chinh danh
sach list do dang bi BUG 1 lam sai gia tri. Khoi dooc lap chua co list nao
mo huong. De nghi doi chieu lai: neu con xac nhan, xem co can bao ve thu tu
danh giá (alias truoc khi truyen) khong.


## BUG 4 (CHUA TAI HIEN) - tinh hinh shape tinh cua container

Khi doi `named_tensor()` trong `session.tkv` tu gan field
(`t = NamedTensor(...); t.data = data`) sang truyen qua `.ctor`
(`return NamedTensor(name, data, [], [])`), **ca module bien dich that bat**
voi loi compile `Index was out of range` (khong co so dong). Bo bien chay
duoc. Sau khi khoi phuc ban gan-field thi bien dich lai binh thuong.

Khong loai ra duoc. Ghi lai de phong khi co ai sua `named_tensor` roi gap loi
khong ro nguyen nhan. Kiem tra them: co phai do mirror `tv.*.tkv` bi cu (stale)
hay khong - luc do nhieu ban mirror cua `session.tkv` dang khac nhau.


## Diem khac can luu y khi kiem tra module

Bien dich la **lazy**: probe `import <module>` chi bat loi cap module, loi
trong than ham chi lo ra khi bien dich entry that (vd `inference_tests.tkv`,
`cli.tkv`). 52/52 module "PASS" khong dong nghia la source sach.


## VI TRI SUA TRONG SOURCE COMPILER

**Sua file modul trong `compiler_bootstrap/`, KHONG sua `build/selfhost/tv_gop.tkv`**
- `compiler_bootstrap/compiler/**` moi la source; `build/selfhost/tv_gop.tkv`
la **ban merge** cua toan bo cac file do (nen dong so trong ghi chu cu noi
dung bien dich la dong cua file merge, lech so dong that).

| bug   | file sua                                       | vi tri                                                    |
|-------|------------------------------------------------|-----------------------------------------------------------|
| BUG 1 | `compiler_bootstrap\compiler\il_features\record_feature.tkv` | `codegen_attr_assign` (dong 110), **nhanh container** dong ~173: `if not field_dtype.la_vo_huong():` -> `compile_expr` roi `stfld` |
| BUG 2 | `compiler_bootstrap\compiler\il_features\operators.tkv`       | dong **362, 480, 489** - noi phat `add.ovf`/`sub.ovf`/`mul.ovf` |

Lien quan BUG 2 (cung phat `*.ovf`, nen doi dong nhat de khong lo):
- `compiler\il_codegen.tkv:1117`
- `compiler\il_core.tkv:1001`
- `compiler\il_features\int_type.tkv:7`

Repro toi thieu cho BUG 1: file `.tkv` doc lap, class co 1 field
`v: 'list[f32]'`, tao list bang `.append(1.0/2.0/3.0)` **trong cung ham**,
truyen cho `.ctor` -> `len()` dung, 3 phan tu sai. Kiem ca 2 chieu doc va ghi,
chi doc `len()` se bo loi sot. Kiem chung them: list do ham khac tao ra thi
DUNG, nen can so sanh ca 2 cach trong cung mot file khi sua.