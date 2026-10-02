# -*- coding: utf-8 -*-
"""Anh xa ten kieu .NET (Type.FullName) sang dtype TokenVector. Dung
DUNG 6 cap giong _EXTERN_DTYPE_TO_IL (tkv_compile.py:1019) - KHONG them
kieu nao khac ngoai Phase 9b's 'bool' (char/... van la fast-follow, chua
lam). Phase 9c (2026-08-26) them map_enum() ham phu de ho tro enum backed
by System.Int32."""

import re

_DOTNET_TO_TKV = {
    "System.Int32": "i32",
    "System.Int64": "i64",
    "System.Single": "f32",
    "System.Double": "f64",
    "System.String": "str",
    "System.Boolean": "bool",
}

# Final review Phase 9c (2026-08-26, Important #1): PHAI khop CHINH XAC
# cung grammar voi _EXTERN_ENUM_DTYPE_RE/_EXTERN_ASSEMBLY_NAME_RE/
# _EXTERN_CLASS_NAME_RE trong tkv_compile.py (dot-separated identifiers,
# moi doan [A-Za-z_][A-Za-z0-9_]*) - CHEP LAI o day (khong import tu
# tkv_compile.py de tranh phu thuoc nguoc tools/tkv_bind -> compiler).
# Neu 2 grammar lech nhau, map_enum() co the sinh ra dtype string ma
# _is_valid_extern_dtype() cua compiler tu choi -> TranspileError cho
# TOAN BO file .tkv do tkv-bind sinh ra (khong chi 1 method/ctor bi bo
# qua) - vd Type.FullName cua 1 enum long trong class khac (nested enum,
# dang "Ns.Outer+Inner", co dau '+') hoac ten assembly co dau '-' deu la
# input .NET hop le nhung KHONG khop grammar nay.
_IDENTIFIER_DOTTED_RE = re.compile(
    r'^[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*$')


def map_scalar(dotnet_full_type_name):
    return _DOTNET_TO_TKV.get(dotnet_full_type_name)


def map_enum(full_name, enums_info, known_assemblies):
    """Phase 9c (2026-08-26): tra ve dtype dac biet 'enum:<assembly>:<FullName>'
    cho 1 kieu enum DA duoc reflector.cs thu thap trong enums_info (dict
    FullName -> {'underlyingType':..., 'assembly':...}) - CHI khi
    underlyingType la System.Int32 (tuong thich bit-for-bit voi i32 tren
    CIL stack; underlying KHAC - Byte/Int16/Int64 - ngoai pham vi Phase 9c,
    tra None). full_name KHONG co trong enums_info (khong phai enum, hoac
    khong xuat hien lam tham so/return o dau ca) cung tra None.

    known_assemblies: tap ten assembly "biet truoc la an toan" cho lan
    chay nay - assembly dang duoc quet (tranh __tkv_extern_assembly__
    tro toi 1 assembly ilasm khong resolve duoc) hop voi cac assembly GAC
    mac dinh cua compiler (generator.py's _DEFAULT_ASSEMBLIES). Final
    review Phase 9c (Important #2): enum tu 1 assembly KHAC (khong nam
    trong known_assemblies) tra None - bi bo qua nhu 1 kieu khong map
    duoc thay vi sinh __tkv_extern_assembly__ tro toi assembly la, se
    khien ilasm khong resolve duoc va that bai TOAN BO file.

    Final review Phase 9c (Minor #6): dung .get() thay vi [] cho
    underlyingType de 1 muc enums_info bi thieu key nay tra None thay vi
    KeyError."""
    info = enums_info.get(full_name)
    if info is None:
        return None
    if info.get("underlyingType") != "System.Int32":
        return None
    assembly = info["assembly"]
    if assembly not in known_assemblies:
        return None
    if not _IDENTIFIER_DOTTED_RE.match(assembly):
        return None
    if not _IDENTIFIER_DOTTED_RE.match(full_name):
        return None
    return "enum:%s:%s" % (assembly, full_name)


def map_object(full_name):
    """Phase 9d Part B (2026-08-27): System.Object lam tham so/return -
    dtype co dinh 'object' (KHONG can mang theo assembly/FullName rieng
    nhu enum, vi CHI co dung 1 kieu .NET duy nhat anh xa toi day). Chi
    khop CHINH XAC 'System.Object' - MOI kieu khac (ke ca System.Type)
    tra None, de tranh nham lan voi map_type()/map_scalar()."""
    return "object" if full_name == "System.Object" else None


def map_type(full_name):
    """Phase 9d Part B (2026-08-27): System.Type lam tham so/return -
    dtype co dinh 'type'. Chi khop CHINH XAC 'System.Type' (KHONG khop
    System.RuntimeType hay cac subclass runtime khac cua Type - reflector
    tra FullName THAT cua tham so trong chu ky method, la 'System.Type'
    trong moi truong hop thuc te vi .NET API cong khai LUON khai tham so
    kieu System.Type, khong bao gio khai truc tiep RuntimeType)."""
    return "type" if full_name == "System.Type" else None


# Phase 9g (2026-08-27): CHI 5 kieu scalar co IL text ngan gon, an toan
# marshal 2 chieu qua List<T>.ToArray()/List<T>::.ctor(IEnumerable<T>)
# (xem tkv_compile.py's _EXTERN_ARRAY_DTYPE_RE - PHAI khop CHINH XAC tap
# nay, khong duoc lech). 'bool' loai co chu dich - xem Global Constraints
# cua plan Phase 9g.
_ARRAY_ELEM_DTYPES = frozenset({"i32", "i64", "f32", "f64", "str"})


def map_array(full_name, handle_types=None):
    """Phase 9g (2026-08-27): .NET mang 1 chieu cua 1 kieu scalar da biet
    (vd 'System.String[]') -> dtype 'array[T]'. Phase 9h (2026-08-27): mo
    rong T sang 1 handle-type DA biet (tham so 'handle_types', dict
    full_name -> short_name tu Pass 1 cua generator.py, mirror pattern
    Phase 9f's _map_params) - 'array[Widget]' vd cho 'My.Widget[]' khi
    'My.Widget' da la 1 handle-type. Mac dinh handle_types=None (tuong
    thich nguoc HOAN TOAN - loi goi cu Phase 9g khong truyen tham so nay
    van chi map duoc 5 scalar, khong doi hanh vi).

    Reflection's Type.FullName cho 1 mang 1 chieu la '<ElementFullName>[]'
    - mang da chieu ('T[,]') KHONG ket thuc bang '[]' don gian nen tu dong
    bi loai; mang long nhau ('T[][]') co phan tu la 'T[]' (khong nam trong
    _DOTNET_TO_TKV cung khong nam trong handle_types) nen ca 2 nhanh deu
    tra None dung thiet ke - KHONG can guard rieng.

    Phase 9i (2026-08-28): mo rong them 1 nhanh DE QUY cho mang LONG 1
    cap - '.NET Type.FullName' cua 'int[][]' (jagged 2 chieu) la
    'System.Int32[][]' - full_name o day (sau khi cat 2 ky tu '[]' cuoi
    o vong goi NGOAI) la 'System.Int32[]', CHINH NO cung ket thuc bang
    '[]' -> goi DE QUY map_array(elem, handle_types) (Phase 9i: CHI 5
    scalar). Neu ket qua de quy CHINH NO lai la 1 chuoi 'array[array[...]]'
    (nghia la full_name that ra la mang 3 lop tro len, vd 'int[][][]') ->
    tra ve None (KHONG ho tro, dung Global Constraint 'CHI 1 cap long').

    Phase 9j (2026-08-28): SUA lai quyet dinh Phase 9i o tren - nhanh de
    quy nay GIO TRUYEN TIEP 'handle_types' (khong con ep ve None) de
    'array[array[HandleType]]' (HandleType DA khai trong file) duoc chap
    nhan, KHOP voi validate moi cua tkv_compile.py
    (_validate_extern_class_container_dtype's nhanh 'array[array[' +
    extern_class_defs). Guard 'khong duoc ra array[array[array[...]]]'
    (3 lop) VAN giu nguyen o cuoi ham - CHI so lop long bi chan, khong
    con chan rieng theo T la scalar hay handle-type nua."""
    if not full_name.endswith("[]"):
        return None
    elem = full_name[:-2]
    elem_dt = map_scalar(elem)
    if elem_dt is not None and elem_dt in _ARRAY_ELEM_DTYPES:
        return "array[%s]" % elem_dt
    if handle_types is not None and elem in handle_types:
        return "array[%s]" % handle_types[elem]
    if elem.endswith("[]"):
        # Phase 9j (2026-08-28): truyen tiep handle_types xuong de quy
        # (truoc day Phase 9i ep None - CHI 5 scalar). Voi handle_types
        # duoc truyen, de quy 1 lop trong co the khop ca 5 scalar LAN
        # handle-type (map_array's nhanh 'handle_types is not None and
        # elem in handle_types' o TREN trong ham nay) - ket qua van CHI 1
        # cap (guard 'not inner.startswith("array[array[")' ben duoi giu
        # nguyen, chan 2+ cap bat ke T la scalar hay handle-type).
        inner = map_array(elem, handle_types)
        if inner is not None and not inner.startswith("array[array["):
            return "array[%s]" % inner
        return None
    return None


def map_dtype(full_name, enums_info, known_assemblies, handle_types=None):
    """Final review Phase 9d Part B (Minor 2, 2026-08-27): chuoi fallback
    DAY DU 4 buoc (scalar -> enum -> object -> type), goi 1 lan de thay
    the 4 khoi code lap lai het trong generator.py + 1 ban sao doc lap
    trong tally_unmapped_types.py::_is_mappable (5 diem tong cong - da GAY
    ra 1 bug that o Task 4, xem final review). CHI dung cho cac diem goi
    CHAP NHAN dtype 'object'/'type' (__tkv_extern_class__'s ctor/methods/
    static_methods) - diem goi feed __tkv_extern_method__ (Pass 3 cua
    generator.py) KHONG duoc dung ham nay nua sau Critical 2 (dtype
    'object'/'type' bi TranspileError o compile-time cho duong do) - giu
    chuoi rieng CHI scalar->enum o do (xem generator.py's _map_params
    allow_object_type=False va nhanh return-dtype rieng cua Pass 3).
    Phase 9g (2026-08-27): them map_array() o cuoi chuoi fallback.
    Phase 9h (2026-08-27): them tham so 'handle_types' (mac dinh None,
    tuong thich nguoc) - chuyen tiep xuong map_array() de ho tro
    'array[HandleType]'."""
    dt = map_scalar(full_name)
    if dt is None:
        dt = map_enum(full_name, enums_info, known_assemblies)
    if dt is None:
        dt = map_object(full_name)
    if dt is None:
        dt = map_type(full_name)
    if dt is None:
        dt = map_array(full_name, handle_types)
    return dt
