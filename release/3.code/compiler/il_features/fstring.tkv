# -*- coding: utf-8 -*-
"""f-string (Wave 2, 2026-07-29) - macro TEXT-LEVEL (khong sinh CIL rieng,
khong tag AST moi): 'f"...{var}..."' duoc VIET LAI THANH bieu thuc noi
chuoi '(" ... " + str(var) + " ... ")' TRUOC khi dong duoc parse binh
thuong - dung CHUNG co che voi macro 'for x in lst:'/compound-assign da
co (xem MACRO_EXPANDERS trong il_dispatch.py, chay LAP toi diem co dinh
qua _expand_macros trong il_codegen.py).

LY DO lam o muc VAN BAN (khong phai 1 tag AST moi voi codegen rieng):
macro chay TRUOC first-pass suy kieu, nen KHONG THE biet {var} la string
hay so tai thoi diem nay - giai phap: LUON boc str(var) (Python that:
str(mot_chuoi) tra ve chinh no) - str() da duoc mo rong ho tro pass-through
cho bien da la string (xem string_feature.py's compile_str_builtin,
sua CUNG luc voi macro nay) nen ket qua DUNG ca 2 truong hop ma khong
can macro biet dtype.

GIOI HAN DA BIET (co chu dich, khong phai thieu cong suc):
- CHI ho tro '{ten_bien}'/'{ten_bien:.Nf}' (1 IDENT tran + format spec
  SO THAP PHAN co dinh tuy chon, KHONG bieu thuc phuc tap vd '{x+1}'/
  '{obj.field}') - khop dung gioi han hien co cua str() (chi nhan 1 BIEN
  don, xem compile_str_builtin/compile_fmt_float) - f-string phuc tap
  hon se can str() ho tro bieu thuc truoc, ngoai pham vi hien tai.
- Format spec (Wave 3, 2026-07-29): CHI ho tro dang '.Nf' (vd '{x:.2f}'
  - N chu so thap phan CO DINH, giong Python that '%.2f') - viet lai
  THANH 'fmt_float(var, N)' (xem string_feature.py's compile_fmt_float)
  thay vi 'str(var)'. KHONG ho tro cac dang spec khac (vd '{x:>10}'/
  '{x:,}'/'{x:e}').
- KHONG ho tro dau ngoac kep ESCAPE ben trong f-string (giong han che
  co san cua tokenizer string thuong trong du an, xem STR_LIT_RE o
  il_core.py - khong rieng cho f-string)."""
import re

from il_dispatch import register_macro_expander

_FSTRING_RE = re.compile(r'f"([^"]*)"')
_FSTRING_VAR_RE = re.compile(r'\{(\w+)(:\.(\d+)f)?\}')


def _fstring_to_concat_expr(content: str) -> str:
    """'Hello {name}, gia {price:.2f}' -> '("Hello " + str(name) + ", gia " + fmt_float(price, 2))'.
    Phan van ban RONG (lien tiep 2 '{var}' hoac o dau/cuoi) duoc BO QUA
    (khong noi '"" + ...' thua). _FSTRING_VAR_RE.split voi 3 group tra
    ve list [literal, var, full_spec_or_None, precision_or_None, literal, ...]
    - buoc 3 phan tu 1 ('var','full_spec','precision') cho MOI lan khop."""
    pieces = _FSTRING_VAR_RE.split(content)
    parts = []
    i = 0
    while i < len(pieces):
        literal = pieces[i]
        if literal:
            parts.append(f'"{literal}"')
        if i + 1 >= len(pieces):
            break
        var_name, precision = pieces[i + 1], pieces[i + 3]
        if precision is not None:
            parts.append(f'fmt_float({var_name}, {precision})')
        else:
            parts.append(f'str({var_name})')
        i += 4
    if not parts:
        return '""'
    return '(' + ' + '.join(parts) + ')'


_IDENT_CH = set('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_')


def try_expand_fstring(line: str):
    """MACRO_EXPANDERS entry - thay THE (co the NHIEU lan xuat hien tren
    CUNG 1 dong) tung f-string literal bang bieu thuc noi chuoi tuong
    duong. Tra None neu dong khong co f-string nao (dung vong lap
    _expand_macros hoi tu, xem docstring module).

    PHAI quet co trang thai chuoi, KHONG duoc dung regex tren ca dong:
    `f"` xuat hien ben trong MOT CHUOI THUONG ket thuc bang chu 'f'. Vi du
    that da lam hong ca cong cu:

        if w == "def" or w == "class":

    Regex cu khop `f" or w == "` (chu 'f' cuoi cua "def" + nhay dong) roi
    viet lai thanh `"de(" ... ")class"` - dieu kien LUON sai, khong bao loi.
    Bang dinh nghia cua typegraph rong sach, 0 canh `calls`. Nguon chuoi
    "def"/"self"/"elif" deu ket thuc bang 'f' nen bay nay rat de gap.

    Hai dieu kien de coi la f-string that: dang o NGOAI moi chuoi, va ky tu
    ngay truoc 'f' khong phai ky tu dinh danh (de `xf"..."` khong bi nhan)."""
    if 'f"' not in line:
        return None
    out = []
    i = 0
    n = len(line)
    changed = False
    while i < n:
        ch = line[i]
        # Chuoi ba nhay: nuot nguyen cum de khong lam lech trang thai.
        if line.startswith('"""', i) or line.startswith("'''", i):
            out.append(line[i:i + 3])
            i += 3
            continue
        if ch == 'f' and i + 1 < n and line[i + 1] == '"':
            prev = line[i - 1] if i > 0 else ''
            if prev not in _IDENT_CH:
                end = line.find('"', i + 2)
                if end >= 0:
                    out.append(_fstring_to_concat_expr(line[i + 2:end]))
                    i = end + 1
                    changed = True
                    continue
        if ch == '"' or ch == "'":
            end = line.find(ch, i + 1)
            if end < 0:
                out.append(line[i:])
                break
            out.append(line[i:end + 1])
            i = end + 1
            continue
        out.append(ch)
        i += 1
    if not changed:
        return None
    return ''.join(out)


register_macro_expander('fstring', try_expand_fstring)
