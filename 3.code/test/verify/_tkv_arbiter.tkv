# -*- coding: utf-8 -*-
"""Harness dung chung: chay MOT cong cu .tkv bang CA HAI duong roi doi chieu.

Vi sao can file nay
-------------------
15 test cong cu (ctxpack, typegraph, layers, domain, impact, ...) hien
KHONG BIEN DICH GI CA. Chung `exec` file .tkv duoi CPython voi read_file/
write_file bi thay bang lambda tro vao mot dict, roi so voi ket qua viet
tay. **Xoa sach compiler thi chung van xanh** — tuc chung kiem tra logic
cua cong cu, khong kiem tra TokenVector. Cong lai la 4436/6911 dong (64%)
ma .tkv THAT chua bao gio gap compiler.

Phat hien khien viec chuyen doi re: **ca 15 cong cu deu co entry
`run(...) -> "str"` voi tham so TOAN `str`** — dung tap `compile_tkv_cli`
ho tro. Chung khong he kho bien dich; chung duoc viet voi file gia chi vi
tien tay. Nen day la MOT harness dung chung, khong phai 15 ban viet lai.

Cach dung (thay cho `run_case` tu che cua tung test)
---------------------------------------------------
    from _tkv_arbiter import run_both

    res = run_both('ctxpack.tkv', 'run',
                   files={'N': nodes, 'I': imports, ...},
                   args=['N', 'I', 'C', 'L', target, str(budget), 'O'],
                   out_files=['O'])
    res.line          # gia tri tra ve (da doi chieu 2 phia)
    res.written['O']  # noi dung file xuat ra (da doi chieu 2 phia)

`run_both` NEM AssertionError ngay khi hai phia lech nhau, nen than
assertion san co cua tung test giu nguyen: no van doc ket qua phia CPython
nhu cu, chi khac la gio da co bao dam ban bien dich cho y het.

Ba diem thiet ke dang chu y
---------------------------
1. **Hai thu muc tam RIENG.** Neu dung chung, ban .exe se doc phai file do
   ban CPython vua ghi ra, va phep doi chieu thanh vo nghia.
2. **Khong viet lai ma nguon.** Ban cu lam `s.replace('__tkv_import__ =
   "impgraph"', "")` — tuc chinh co che import dang duoc kiem lai bi vo
   hieu hoa. Thua: `__tkv_import__ = "impgraph"` chay duoi CPython chi la
   mot phep gan chuoi, hoan toan vo hai. Ta giai quyet chuoi import theo
   DUNG luat cua compiler (cung thu muc, de quy, khu trung theo duong dan
   tuyet doi) nen hai phia khong the lech nhau ve *file nao duoc nap*.
3. **So ca noi dung FILE XUAT RA, khong chi gia tri tra ve.** Cac cong cu
   nay lam viec chinh bang cach ghi file; chi so dong tra ve thi bo sot
   gan het hanh vi.
"""
import ast
import hashlib
import io
import os
import shutil
import subprocess
import sys
import tempfile
import types
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli  # noqa: E402

TOOLS = Path(__file__).parent.parent.parent / 'tools'


class ArbiterResult(object):
    """Ket qua da duoc doi chieu giua hai phia."""

    def __init__(self, line, written, py_line, exe_line):
        self.line = line          # gia tri tra ve (hai phia da khop)
        self.written = written    # {ten file: noi dung} (hai phia da khop)
        self.py_line = py_line
        self.exe_line = exe_line


def _import_chain(tkv_path, seen=None, order=None):
    """Thu tu nap file theo DUNG luat cua extract_program_file: tim
    '<ten>.tkv' trong CUNG thu muc, de quy, khu trung theo duong dan tuyet
    doi. Phu thuoc nap TRUOC file phu thuoc no."""
    tkv_path = Path(tkv_path).resolve()
    if seen is None:
        seen, order = set(), []
    if str(tkv_path) in seen:
        return order
    seen.add(str(tkv_path))
    tree = ast.parse(io.open(tkv_path, encoding='utf-8').read())
    names = []
    for node in tree.body:
        if (isinstance(node, ast.Assign) and len(node.targets) == 1
                and isinstance(node.targets[0], ast.Name)
                and node.targets[0].id == '__tkv_import__'):
            val = node.value
            if isinstance(val, ast.Constant) and isinstance(val.value, str):
                names = [val.value]
            elif isinstance(val, (ast.List, ast.Tuple)):
                names = [e.value for e in val.elts
                         if isinstance(e, ast.Constant)]
    for name in names:
        _import_chain(tkv_path.parent / (name + '.tkv'), seen, order)
    order.append(tkv_path)
    return order


def _make_namespace(tkv_path, workdir):
    """Khong gian ten CPython cho 1 file .tkv, I/O tro vao workdir."""
    mod = types.ModuleType(Path(tkv_path).stem)

    def read_file(p):
        # Che do VAN BAN (mac dinh) = universal newlines cua Python: '\r\n'
        # va '\r' don le deu thanh '\n'. Ban bien dich cung lam vay ke tu
        # 2026-08-04 (xem file_io.py's compile_read_file) - truoc do KHONG,
        # va do la mot lech am tham that su.
        return io.open(os.path.join(workdir, p), encoding='utf-8').read()

    def write_file(p, c):
        dest = os.path.join(workdir, p)
        parent = os.path.dirname(dest)
        if parent:
            os.makedirs(parent, exist_ok=True)
        # newline='' — xem ghi chu o run_both: phai ghi nguyen van de hai
        # phia thay cung mot chuoi byte.
        with io.open(dest, 'w', encoding='utf-8', newline='') as fh:
            fh.write(c)

    def file_exists(p):
        return os.path.exists(os.path.join(workdir, p))

    mod.__dict__['read_file'] = read_file
    mod.__dict__['write_file'] = write_file
    mod.__dict__['file_exists'] = file_exists
    # sha256_hex la builtin DSL DUY NHAT ma tools/*.tkv dung va CPython
    # khong co san. Uy nhiem MOT DONG sang hashlib that - dung khuon
    # tkvcalc_test.py:18 ({'floor': math.floor, ...}), khong phai viet lai.
    mod.__dict__['sha256_hex'] = (
        lambda s: hashlib.sha256(s.encode('utf-8')).hexdigest())
    for path in _import_chain(tkv_path):
        # KHONG sua ma nguon: '__tkv_import__ = "x"' duoi CPython chi la
        # mot phep gan chuoi vo hai.
        src = io.open(path, encoding='utf-8').read()
        exec(compile(src, path.name, 'exec'), mod.__dict__)
    return mod


def _run_cpython(tkv_path, entry, workdir, args):
    """Chay 1 entry duoi CPython that."""
    mod = _make_namespace(tkv_path, workdir)
    return mod.__dict__[entry](*args)


def _run_compiled(tkv_path, entry, workdir, args):
    """Bien dich .tkv roi chay .exe voi cwd = workdir."""
    # KHONG ghi vao %TEMP% (2026-08-05). Nhat ky Defender cho thay duong
    # tinh gia 'Wacatac.B!ml' CHI xay ra o day - dung la duong duy nhat
    # ghi .exe vao %TEMP%; moi test khac ghi trong cay repo va chua bao
    # gio bi chan. Mot PE moi tinh, khong ky so, nam trong %TEMP%, do
    # python.exe ghi ra roi chay ngay chinh la khuon dropper ma mo hinh
    # hoc may duoc huan luyen de bat.
    exe_dir = Path(__file__).resolve().parents[1] / '_exe'
    exe_dir.mkdir(exist_ok=True)
    exe = exe_dir / ('_arb_%s_%s.exe' % (Path(tkv_path).stem, entry))
    if exe.exists():
        exe.unlink()
    compile_tkv_cli(Path(tkv_path), exe, entry_name=entry)
    r = subprocess.run([str(exe)] + [str(a) for a in args], cwd=workdir,
                       capture_output=True, text=True, errors='replace',
                       timeout=300)
    if r.returncode != 0:
        raise AssertionError(
            "ban BIEN DICH cua %s::%s thoat voi ma %s\nstdout: %s\nstderr: %s"
            % (Path(tkv_path).name, entry, r.returncode,
               r.stdout[-800:], r.stderr[-800:]))
    return r.stdout.rstrip('\r\n')


class ArbiterSession(object):
    """Nhu run_both nhung GIU TRANG THAI qua nhieu lan goi.

    Can cho cong cu chay nhieu buoc noi tiep: graphstale chay `save` de ghi
    file van tay, roi chay `check` doc lai chinh file do. Voi run_both (moi
    lan mot thu muc tam roi xoa) thi buoc hai khong thay gi ca.

    Hai thu muc rieng van duoc giu nguyen - trang thai cua phia CPython va
    phia bien dich tien hoa doc lap, va duoc doi chieu sau MOI buoc. Nho vay
    neu buoc `save` ghi ra hai file van tay khac nhau thi hong lo ra NGAY,
    khong doi den khi `check` cho ket qua kho hieu.

        s = ArbiterSession('graphstale.tkv', files={...})
        try:
            s.run('run', ['M', 'FP', 'save', 'CH'], out_files=['FP'])
            r = s.run('run', ['M', 'FP', 'check', 'CH'], out_files=['CH'])
        finally:
            s.close()
    """

    def __init__(self, tkv_name, files):
        self.tkv_path = TOOLS / tkv_name
        self.tkv_name = tkv_name
        self.py_dir = tempfile.mkdtemp(prefix='tkvarb_py_')
        self.exe_dir = tempfile.mkdtemp(prefix='tkvarb_exe_')
        for wd in (self.py_dir, self.exe_dir):
            _write_files(wd, files)

    def write(self, files):
        """Do them/ghi de file vao CA HAI thu muc giua cac buoc."""
        for wd in (self.py_dir, self.exe_dir):
            _write_files(wd, files)

    def run(self, entry, args, out_files=()):
        py_line = _run_cpython(self.tkv_path, entry, self.py_dir, args)
        exe_line = _run_compiled(self.tkv_path, entry, self.exe_dir, args)
        _compare(self.tkv_name, entry, py_line, exe_line)
        written = _compare_outputs(self.tkv_name, entry, out_files,
                                   self.py_dir, self.exe_dir)
        return ArbiterResult(py_line, written, py_line, exe_line)

    def close(self):
        shutil.rmtree(self.py_dir, ignore_errors=True)
        shutil.rmtree(self.exe_dir, ignore_errors=True)


def _write_files(workdir, files):
    for name, content in files.items():
        # Ten file co the chua thu muc con ('app/x.py' trong defmeta_test).
        dest = os.path.join(workdir, name)
        parent = os.path.dirname(dest)
        if parent:
            os.makedirs(parent, exist_ok=True)
        # newline='' — KHONG dich '\n' thanh '\r\n'. Xem ghi chu o run_both.
        with io.open(dest, 'w', encoding='utf-8', newline='') as fh:
            fh.write(content)


def _compare(tkv_name, entry, py_line, exe_line):
    if str(py_line) != str(exe_line):
        raise AssertionError(
            "%s::%s — gia tri tra ve LECH giua CPython va ban bien dich\n"
            "  CPython      : %r\n  ban bien dich: %r"
            % (tkv_name, entry, py_line, exe_line))


def _compare_outputs(tkv_name, entry, out_files, py_dir, exe_dir):
    written = {}
    for name in out_files:
        got = {}
        for label, wd in (('CPython', py_dir), ('bien dich', exe_dir)):
            p = os.path.join(wd, name)
            got[label] = (io.open(p, encoding='utf-8').read()
                          if os.path.exists(p) else None)
        if got['CPython'] != got['bien dich']:
            raise AssertionError(
                "%s::%s — file xuat ra %r LECH giua hai phia\n"
                "  CPython      : %r\n  ban bien dich: %r"
                % (tkv_name, entry, name, (got['CPython'] or '')[:400],
                   (got['bien dich'] or '')[:400]))
        if got['CPython'] is None:
            raise AssertionError(
                "%s::%s — khong phia nao ghi ra file %r"
                % (tkv_name, entry, name))
        written[name] = got['CPython']
    return written


def run_both(tkv_name, entry, files, args, out_files=()):
    """Chay ca hai phia tren cung dau vao, doi chieu, tra ArbiterResult.

    Truong hop MOT BUOC cua ArbiterSession - dung chung y het duong so sanh
    (neu tach hai ban thi som muon chung se bat dong ve the nao la "giong").

    files    : {ten file: noi dung} do vao thu muc lam viec truoc khi chay
    args     : doi so vi tri (deu la str - dung tap CLI ho tro)
    out_files: ten cac file ma cong cu GHI RA, can doi chieu noi dung
    """
    session = ArbiterSession(tkv_name, files)
    try:
        return session.run(entry, args, out_files)
    finally:
        session.close()
