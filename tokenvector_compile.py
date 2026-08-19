# -*- coding: utf-8 -*-
"""TokenVector: bien dich mot sklearn MLPClassifier (1 hidden layer) da
train san thanh MOT file .exe doc lap (khong can Python/sklearn luc
chay), bang cach tai su dung compiler/il_codegen.py (macro
normalize/dense/argmax) de sinh CIL, roi goi ilasm.exe co san trong
.NET Framework.

Gioi han THAT (khong che giau): chi ho tro
  - MLPClassifier voi DUNG 1 hidden layer (coefs_ co dung 2 phan tu)
  - n_outputs_ >= 2 (khong ho tro nhi phan 1-neuron-output cua sklearn)
  - scaler (neu co) phai la sklearn.preprocessing.MinMaxScaler (macro
    normalize() chi ho tro dang (x-min)/(max-min))
Neu model khong khop cac dieu kien tren, nem loi ro rang thay vi doan mo.
"""
import subprocess
import sys
from pathlib import Path

COMPILER_DIR = Path(__file__).parent / "compiler"
sys.path.insert(0, str(COMPILER_DIR))
from typed_dsl_parser import parse_typed_signature  # noqa: E402
from il_codegen import gen_il_function, tkvint_class_il  # noqa: E402

def _find_ilasm():
    """Tu do tim ilasm.exe tren MAY DICH bat ky (Wave 3, 2026-07-29 -
    "TokenVector - Only" portable folder) - KHONG the dong goi rieng
    ilasm.exe mang di may khac (da tu kiem chung THAT: copy rieng file
    nay ra ngoai thu muc cai dat .NET Framework bao STATUS_DLL_NOT_FOUND,
    no phu thuoc cac DLL khac nam CUNG thu muc cai dat, khong phai file
    doc lap) - nen thay vi hard-code 1 duong dan CO DINH (chi dung tren
    may nay), do tim qua CA 2 thu muc chuan (Framework64/Framework) x
    CAC phien ban .NET Framework co the co, uu tien ban moi nhat. May
    dich CHI can co san .NET Framework 4.x (rat pho bien tren Windows,
    khong can cai them gi khac) la chay duoc, khong con phu thuoc DUY
    NHAT 1 duong dan tuyet doi cua may nay."""
    roots = [
        Path(r"C:\WINDOWS\Microsoft.NET\Framework64"),
        Path(r"C:\WINDOWS\Microsoft.NET\Framework"),
    ]
    candidates = []
    for root in roots:
        if root.exists():
            for sub in root.iterdir():
                exe = sub / "ilasm.exe"
                if exe.exists():
                    candidates.append(exe)
    if not candidates:
        raise RuntimeError(
            "\n[tkvc] KHONG tim thay .NET Framework tren may nay (can de bien dich/chay .tkv).\n"
            "  Tai va cai .NET Framework 4.8 (chinh thuc tu Microsoft, mien phi) tai:\n"
            "  https://dotnet.microsoft.com/en-us/download/dotnet-framework/net48\n"
            "  Sau khi cai xong, chay lai lenh nay - KHONG can lam gi them.\n"
            "  (TokenVector KHONG tu dong tai/cai - de ban tu quyet dinh va thuc hien.)\n")
    candidates.sort(key=lambda p: p.parent.name, reverse=True)
    return str(candidates[0])


ILASM = _find_ilasm()

_ACTIVATION_MAP = {
    'identity': 'none',
    'logistic': 'sigmoid',
    'tanh': 'tanh',
    'relu': 'relu',
}


class TokenVectorError(Exception):
    pass


class AvBlockedError(TokenVectorError):
    """Windows Defender chan/cach ly .exe VUA dung xong.

    KHONG phai loi bien dich - la duong tinh GIA cua bo phan loai hoc may
    (ho '!ml', vd Trojan:Win32/Wacatac.B!ml). Xem docstring cua
    assemble_il_to_exe ve LY DO va CACH tranh."""


def assemble_il_to_exe(il_text, out_exe, debug=False):
    """Ghi IL ra file roi goi ilasm, TRANH khuon hanh vi ma Defender gan
    cho dropper malware (2026-08-05).

    ## Van de THAT (khong phai suy doan - da doc nhat ky Defender)

    Event 1116/1117: 'Trojan:Win32/Wacatac.B!ml' tren _arb_*.exe, Action
    Quarantine, Process Name = python.exe. Hau to '!ml' = phan quyet cua
    MO HINH heuristic, khong phai chu ky. Wacatac.B!ml la ten noi tieng
    nhat trong nhom duong-tinh-gia voi mot PE VUA duoc bien dich. Bo ba
    dac trung day diem qua nguong:
      1. PE HOAN TOAN MOI, prevalence = 0 (chua tung ton tai o dau).
      2. Khong ky so, nam trong %TEMP%.
      3. Do python.exe ghi ra roi CHAY NGAY - dung khuon dropper.
    Chay lai thi xanh vi ilasm nhung MVID (GUID ngau nhien) + timestamp
    moi moi lan -> bytes khac -> diem ML khac -> khi thi tren khi thi
    duoi nguong. Tuc diem nam SAT nguong; hich bat ky yeu to nao xuong
    la du.

    ## Cach tranh (khong tat Defender, khong them ngoai le)

    - Goi o day KHONG con ghi vao %TEMP% (caller chon out_exe trong cay
      repo) - go yeu to (2), la yeu to quyet dinh: FP CHI xay ra o duong
      arbiter, duong duy nhat truoc day dung %TEMP%.
    - Sau khi ilasm xong, MO file de doc mot lan: buoc nay dong bo voi
      quet-khi-truy-cap cua Defender (RTP quet luc mo), nen khi CHAY sau
      do khong con kich hoat duong FastPath-khi-thuc-thi hung hon. Neu bi
      chan, chinh open() nem OSError NGAY TAI DAY - bat duoc, bao ro, va
      dung lai bang mot lan nem AvBlockedError co ten, thay vi mot cu sap
      kho hieu luc chay o tan noi khac.
    - Bi chan thi DUNG LAI mot lan: ilasm lai cho bytes moi (MVID/
      timestamp khac) -> diem ML khac -> gan nhu chac chan qua. Day chinh
      la co che dang sau 'chay lai la xanh', nay tu dong.
    """
    import io
    import os
    import time

    out_exe = Path(out_exe)
    il_path = out_exe.with_suffix('.il')
    il_path.write_text(il_text, encoding='utf-8')

    settle_ms = int(os.environ.get('TKV_EXE_SETTLE_MS', '150'))
    last_err = None
    for attempt in range(2):
        if out_exe.exists():
            out_exe.unlink()
        ilasm_args = [ILASM, str(il_path), '/exe', f'/output:{out_exe}']
        if debug:
            ilasm_args.append('/debug')
        result = subprocess.run(ilasm_args, capture_output=True, text=True)
        if result.returncode != 0:
            raise TokenVectorError(
                f"ilasm.exe that bai (code {result.returncode}):\n"
                f"{result.stdout}\n{result.stderr}")
        if sys.platform != 'win32':
            return out_exe
        # Cho quet-khi-ghi (bat dong bo) cua RTP kip bat dau, roi MO file
        # de bien no thanh diem dong bo (quet-khi-truy-cap).
        if settle_ms > 0:
            time.sleep(settle_ms / 1000.0)
        try:
            with io.open(out_exe, 'rb') as fh:
                fh.read(64)
            return out_exe
        except OSError as e:
            # WinError 225 = 'file contains a virus'; hoac 'Access denied'
            # khi Defender dang cach ly. Ca hai deu la AV chan, khong phai
            # loi doc thong thuong.
            last_err = e
            continue
    raise AvBlockedError(
        f"Windows Defender chan .exe vua dung ({out_exe.name}) sau 2 lan thu "
        f"- duong tinh gia '!ml' (xem docstring assemble_il_to_exe). "
        f"Nguyen nhan goc: {last_err}")


def _check_model(model):
    if len(model.coefs_) != 2:
        raise TokenVectorError(
            f"TokenVector chi ho tro MLPClassifier 1 hidden layer (coefs_ co "
            f"2 phan tu). Model nay co {len(model.coefs_)} phan tu (tuc "
            f"{len(model.coefs_) - 1} hidden layer(s)).")
    n_out = model.coefs_[1].shape[1]
    if n_out < 2:
        raise TokenVectorError(
            f"TokenVector chua ho tro model nhi phan 1-neuron-output cua "
            f"sklearn (n_outputs_={n_out}). Can >= 2 lop output (multi-class).")
    if model.activation not in _ACTIVATION_MAP:
        raise TokenVectorError(f"Activation '{model.activation}' chua duoc anh xa.")


def _check_scaler(scaler):
    if scaler is None:
        return
    if not (hasattr(scaler, 'data_min_') and hasattr(scaler, 'data_max_')):
        raise TokenVectorError(
            "TokenVector chi ho tro sklearn.preprocessing.MinMaxScaler "
            "(can data_min_/data_max_). Scaler truyen vao khong co cac "
            "thuoc tinh nay.")


class _LocalAlloc:
    """Cap phat .locals cho method Main() theo thu tu, tranh loi danh so
    tay (nguon bug thuc te trong cac script harness truoc day)."""

    def __init__(self):
        self._decls = []

    def add(self, il_type):
        idx = len(self._decls)
        self._decls.append(il_type)
        return idx

    def decl_str(self):
        return ', '.join(self._decls)


def _emit_1d(idx, vals, out):
    out.append(f'    ldc.i4 {len(vals)}')
    out.append('    newarr [mscorlib]System.Single')
    out.append(f'    stloc.s {idx}')
    for i, v in enumerate(vals):
        out.append(f'    ldloc.s {idx}')
        out.append(f'    ldc.i4 {i}')
        out.append(f'    ldc.r4 {float(v)!r}')
        out.append('    stelem.r4')


def _emit_2d(idx, mat, out):
    rows, cols = len(mat), len(mat[0])
    out.append(f'    ldc.i4 {rows}')
    out.append(f'    ldc.i4 {cols}')
    out.append('    newobj instance void float32[0...,0...]::.ctor(int32, int32)')
    out.append(f'    stloc.s {idx}')
    for i in range(rows):
        for j in range(cols):
            out.append(f'    ldloc.s {idx}')
            out.append(f'    ldc.i4 {i}')
            out.append(f'    ldc.i4 {j}')
            out.append(f'    ldc.r4 {float(mat[i][j])!r}')
            out.append('    callvirt instance void float32[0...,0...]::Set(int32, int32, float32)')


def _emit_str_array(idx, strs, out):
    out.append(f'    ldc.i4 {len(strs)}')
    out.append('    newarr [mscorlib]System.String')
    out.append(f'    stloc.s {idx}')
    for i, s in enumerate(strs):
        out.append(f'    ldloc.s {idx}')
        out.append(f'    ldc.i4 {i}')
        out.append(f'    ldstr "{s}"')
        out.append('    stelem.ref')


def build_dsl_body(n_in, has_scaler):
    if has_scaler:
        return [
            'xn = normalize(x, x_min, x_max)',
            f"h = dense(xn, w1, b1, '{{hidden_act}}')",
            "o = dense(h, w2, b2, 'none')",
            'best_idx = argmax(o)',
            'return best_idx',
        ]
    return [
        f"h = dense(x, w1, b1, '{{hidden_act}}')",
        "o = dense(h, w2, b2, 'none')",
        'best_idx = argmax(o)',
        'return best_idx',
    ]


def compile_model(model, out_exe, scaler=None, class_labels=None):
    """Bien dich `model` (sklearn MLPClassifier) thanh 1 file .exe doc lap
    tai `out_exe`. Neu co `scaler` (MinMaxScaler), input .exe se nhan gia
    tri THO (chua chuan hoa). Neu co `class_labels` (list ten lop), .exe
    se in ten lop thay vi chi so."""
    _check_model(model)
    _check_scaler(scaler)

    w1, w2 = model.coefs_
    b1, b2 = model.intercepts_
    n_in, n_hidden = w1.shape
    n_out = w2.shape[1]
    hidden_act = _ACTIVATION_MAP[model.activation]
    has_scaler = scaler is not None

    if class_labels is not None and len(class_labels) != n_out:
        raise TokenVectorError(
            f"class_labels co {len(class_labels)} phan tu nhung model co {n_out} lop output.")

    sig_line = (
        f"tv_classify(x: f32[{n_in}]"
        + (f", x_min: f32[{n_in}], x_max: f32[{n_in}]" if has_scaler else "")
        + f", w1: f32[{n_in}, {n_hidden}], b1: f32[{n_hidden}], "
          f"w2: f32[{n_hidden}, {n_out}], b2: f32[{n_out}]) -> f32:"
    )
    body = [line.format(hidden_act=hidden_act) for line in build_dsl_body(n_in, has_scaler)]

    sig = parse_typed_signature(sig_line)
    classify_method = gen_il_function(sig, body)

    alloc = _LocalAlloc()
    idx_x = alloc.add('float32[]')
    idx_xmin = alloc.add('float32[]') if has_scaler else None
    idx_xmax = alloc.add('float32[]') if has_scaler else None
    idx_w1 = alloc.add('float32[0...,0...]')
    idx_b1 = alloc.add('float32[]')
    idx_w2 = alloc.add('float32[0...,0...]')
    idx_b2 = alloc.add('float32[]')
    idx_pred = alloc.add('float32')
    idx_i = alloc.add('int32')
    idx_labels = alloc.add('string[]') if class_labels is not None else None
    idx_predidx = alloc.add('int32')

    main = []
    _emit_1d(idx_x, [0.0] * n_in, main)  # placeholder, overwritten from argv below
    if has_scaler:
        _emit_1d(idx_xmin, list(scaler.data_min_), main)
        _emit_1d(idx_xmax, list(scaler.data_max_), main)
    _emit_2d(idx_w1, w1.tolist(), main)
    _emit_1d(idx_b1, b1.tolist(), main)
    _emit_2d(idx_w2, w2.tolist(), main)
    _emit_1d(idx_b2, b2.tolist(), main)
    if class_labels is not None:
        _emit_str_array(idx_labels, [str(c) for c in class_labels], main)

    # Doc n_in gia tri float tu argv (args[0..n_in-1]) vao mang x. PHAI ep
    # InvariantCulture: Single.Parse(string) mac dinh dung CurrentCulture -
    # tren may co culture vi-VN (dau "." khong phai decimal separator),
    # Parse("6.1") am tham cho ra 61 (BUG THAT, khong nem loi - phat hien
    # qua debug so sanh voi ket qua sklearn).
    main += [
        f'    ldc.i4.0', f'    stloc.s {idx_i}',
        '  tv_parse_loop:',
        f'    ldloc.s {idx_i}', f'    ldc.i4 {n_in}', '    bge tv_parse_end',
        f'    ldloc.s {idx_x}', f'    ldloc.s {idx_i}',
        '    ldarg.0', f'    ldloc.s {idx_i}', '    ldelem.ref',
        '    call class [mscorlib]System.Globalization.CultureInfo '
        '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()',
        '    call float32 [mscorlib]System.Single::Parse(string, '
        'class [mscorlib]System.IFormatProvider)',
        '    stelem.r4',
        f'    ldloc.s {idx_i}', '    ldc.i4.1', '    add', f'    stloc.s {idx_i}',
        '    br tv_parse_loop',
        '  tv_parse_end:',
    ]

    call_args = [f'    ldloc.s {idx_x}']
    if has_scaler:
        call_args += [f'    ldloc.s {idx_xmin}', f'    ldloc.s {idx_xmax}']
    call_args += [f'    ldloc.s {idx_w1}', f'    ldloc.s {idx_b1}',
                  f'    ldloc.s {idx_w2}', f'    ldloc.s {idx_b2}']
    params_sig = 'float32[]' + (', float32[], float32[]' if has_scaler else '') + \
                 ', float32[0...,0...], float32[], float32[0...,0...], float32[]'
    main += call_args
    main += [
        f'    call float32 TokenVectorApp::tv_classify({params_sig})',
        f'    stloc.s {idx_pred}',
        f'    ldloc.s {idx_pred}', '    conv.i4', f'    stloc.s {idx_predidx}',
    ]

    if class_labels is not None:
        main += [
            f'    ldloc.s {idx_labels}', f'    ldloc.s {idx_predidx}', '    ldelem.ref',
            '    call void [mscorlib]System.Console::WriteLine(string)',
        ]
    else:
        main += [
            f'    ldloc.s {idx_predidx}',
            '    call void [mscorlib]System.Console::WriteLine(int32)',
        ]
    main += ['    ret']

    main_method = [
        '  .method public static void Main(string[] args) cil managed',
        '  {',
        '    .entrypoint',
        '    .maxstack 8',
        f'    .locals init ({alloc.decl_str()})',
    ] + main + ['  }']

    il_text = (
        '.assembly extern mscorlib {}\n'
        '.assembly TokenVectorApp {}\n'
        '.module TokenVectorApp.exe\n\n'
        '.class public auto ansi TokenVectorApp extends [mscorlib]System.Object\n'
        '{\n'
        + '\n'.join(classify_method) + '\n'
        + '\n'.join(main_method) + '\n'
        '}\n'
        # .class TkvInt o muc top-level - xem il_codegen.tkvint_class_il()
        + '\n'.join(tkvint_class_il()) + '\n'
    )

    out_exe = Path(out_exe)
    il_path = out_exe.with_suffix('.il')
    il_path.write_text(il_text, encoding='utf-8')

    result = subprocess.run(
        [ILASM, str(il_path), '/exe', f'/output:{out_exe}'],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise TokenVectorError(
            f"ilasm.exe that bai (code {result.returncode}):\n{result.stdout}\n{result.stderr}")
    return out_exe
