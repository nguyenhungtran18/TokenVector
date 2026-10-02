# -*- coding: utf-8 -*-
"""tkv-bind tally: dem tan suat cac kieu .NET KHONG map duoc sang scalar/
handle-type/enum, tach theo instance-method-cua-class-eligible vs
static-method-cua-class-KHONG-eligible - dung de sinh cac bang "top kieu
tham so/tra ve KHONG map duoc" trong tai lieu roadmap (Phase 9c va sau).

Vi sao can script rieng, khong dung lai generator.generate() nguyen ven:
generate() (Pass 2/3) goi _map_params(), ham nay early-return None ngay
khi gap THAM SO DAU TIEN khong map duoc trong 1 method - du muc dich cua
_map_params() la quyet dinh method co bind duoc hay khong (dung, chi can
biet CO/KHONG), no KHONG di tiep de liet ke HET cac tham so khac trong
CUNG method cung khong map duoc. Script nay lam lai buoc loc eligibility
(Pass 1, y het generator.py) roi TU duyet tung tham so/tra ve, KHONG
early-return, de dem OCCURRENCE (1 method 2 tham so cung fail tinh 2 lan)
- dung phuong phap Task 5 (Phase 9c, 2026-08-26) da dung de sinh so lieu
trong docs/superpowers/plans/2026-08-20-close-python-gap-roadmap.md,
muc "So lieu that Phase 9c (2026-08-26) - enum -> i32". Lam VIEC NAY
THANH FILE COMMIT de Phase 9d tro di khong lap lai gap "khong tim thay
script tally" da bi phat hien o Phase 9b VA (truoc khi co file nay) Phase 9c.

Vi du:
    python tools/tkv_bind/tally_unmapped_types.py --dll System.dll --top 10
"""
import argparse
import sys
from collections import Counter

from run_reflector import reflect_dll
from type_map import map_scalar, map_enum, map_dtype
from generator import _DEFAULT_ASSEMBLIES


def _is_mappable(full_name, enums_info, known_assemblies, handle_types=None):
    """True neu 1 ten kieu .NET map duoc sang scalar/enum/object/type/
    array[HandleType] - ham nay dung cho duong CLASS-FEEDING (ctor/
    instance method/static method cua handle-type, tuc Pass 1/2 cua
    generator.py). Phase 9d Part B (2026-08-27, do lai): _map_params()
    that trong generator.py fallback tiep sang map_object()/map_type() sau
    map_enum() (them boi Task 1-3 cua Phase 9d Part B) - ham nay PHAI theo
    dung chuoi fallback do, neu khong so lieu tally se bi LECH (dem
    System.Object/System.Type la "khong map duoc" trong khi generator.py
    that su DA bind duoc chung).

    Minor 2 (final review Phase 9d Part B): dung chung
    type_map.map_dtype() thay vi lap lai 4-buoc chain o day - xem
    _is_mappable_static() ben duoi cho duong __tkv_extern_method__ (Pass
    3, Critical 2).

    Final review fix Phase 9h (2026-08-27): them tham so 'handle_types'
    (mac dinh None, tuong thich nguoc), chuyen tiep xuong map_dtype() ->
    map_array() de nhan dien 'array[HandleType]' - Task 2 (Phase 9h) da
    them tham so nay vao map_dtype()/generator.py's Pass 2 (dong 149,
    173) nhung script tally nay bi bo sot, khien tally BAO SAI mot so
    'array[HandleType]' la khong map duoc trong khi generator.py that su
    DA sinh duoc chung (goc re cua so lieu sai trong roadmap doc, xem
    final whole-branch review Phase 9h)."""
    return map_dtype(full_name, enums_info, known_assemblies, handle_types=handle_types) is not None


def _is_mappable_static(full_name, enums_info, known_assemblies, handle_types=None):
    """Critical 2 (final review Phase 9d Part B, 2026-08-27): duong __tkv_
    extern_method__ (Pass 3 cua generator.py, static method tren class
    KHONG phai handle-type) KHONG con chap nhan dtype 'object'/'type' sau
    khi compiler tu choi ro 2 dtype nay tren pragma nay
    (_validate_and_register_extern_method) - ham nay CHI dung map_scalar/
    map_enum (KHONG goi type_map.map_dtype - ham do chay day du ca
    map_object/map_type), mirror dung generator.py's
    _map_params(allow_object_type=False). Dung cho static_param/
    static_return trong tally() ben duoi de so lieu tally khop CHINH XAC
    hanh vi that cua generator.py sau fix Critical 2 (neu khong, 6 muc
    that LicenseManager/TypeDescriptor tren System.dll se bi tinh nham
    la "da bind duoc" trong tally trong khi generator.py THAT SU bo qua
    chung vao skip report).

    Final review fix Phase 9h (2026-08-27): them tham so 'handle_types'
    (mac dinh None) - mirror dung generator.py's _map_params(allow_
    object_type=False, handle_types=...) dong 65-66: sau map_scalar/
    map_enum, fallback CUOI CUNG la kiem tra 'full_name in handle_types'
    (tham so DUNG la 1 handle-type da biet, KHONG phai array[HandleType]
    - nhanh Pass 3 nay khong di qua map_array())."""
    if map_scalar(full_name) is not None:
        return True
    if map_enum(full_name, enums_info, known_assemblies) is not None:
        return True
    if handle_types is not None and full_name in handle_types:
        return True
    return False


def compute_eligibility(reflection_data, known_assemblies):
    """Y het Pass 1 cua generator.py: tra ve (handle_types, eligible_full_names)."""
    enums_info = reflection_data.get("enums") or {}
    handle_types = {}
    eligible_full_names = set()
    for cls in reflection_data["classes"]:
        full_name = cls["fullName"]
        if cls["isGeneric"]:
            continue
        if len(cls["ctors"]) == 0:
            continue
        scalar_ok = False
        for ctor in cls["ctors"]:
            if all(_is_mappable(p, enums_info, known_assemblies) for p in ctor["params"]):
                scalar_ok = True
                break
        if not scalar_ok:
            continue
        handle_types[full_name] = full_name.rsplit(".", 1)[-1].split("`")[0]
        eligible_full_names.add(full_name)
    return handle_types, eligible_full_names


def tally(reflection_data):
    """Tra ve dict voi 4 Counter: instance_param, instance_return,
    static_param, static_return - dung dung logic Pass 2/Pass 3 (bo qua
    method generic, bo qua return da la void/handle-type) nhung KHONG
    early-return o tham so dau tien nhu _map_params() that."""
    enums_info = reflection_data.get("enums") or {}
    assembly_name = reflection_data["assemblyName"]
    known_assemblies = _DEFAULT_ASSEMBLIES | {assembly_name}
    handle_types, eligible_full_names = compute_eligibility(reflection_data, known_assemblies)

    instance_param = Counter()
    instance_return = Counter()
    static_param = Counter()
    static_return = Counter()

    for cls in reflection_data["classes"]:
        full_name = cls["fullName"]
        if full_name in eligible_full_names:
            for m in cls["instanceMethods"]:
                if m["isGeneric"]:
                    continue
                for p in m["params"]:
                    if not _is_mappable(p, enums_info, known_assemblies, handle_types=handle_types):
                        instance_param[p] += 1
                ret = m["returns"]
                if ret == "System.Void" or ret in handle_types:
                    continue
                if not _is_mappable(ret, enums_info, known_assemblies, handle_types=handle_types):
                    instance_return[ret] += 1
        else:
            if cls["isGeneric"]:
                continue
            for m in cls["staticMethods"]:
                if m["isGeneric"]:
                    continue
                for p in m["params"]:
                    # Critical 2 (final review Phase 9d Part B): nhanh nay
                    # feed __tkv_extern_method__ (Pass 3) - dung
                    # _is_mappable_static (KHONG chap nhan object/type nua).
                    if not _is_mappable_static(p, enums_info, known_assemblies, handle_types=handle_types):
                        static_param[p] += 1
                ret = m["returns"]
                if ret == "System.Void":
                    continue
                if not _is_mappable_static(ret, enums_info, known_assemblies, handle_types=handle_types):
                    static_return[ret] += 1

    return {
        "instance_param": instance_param,
        "instance_return": instance_return,
        "static_param": static_param,
        "static_return": static_return,
    }, len(eligible_full_names)


def tally_static_on_handle_type(reflection_data):
    """Dem THAT so static method (tach generic/non-generic) tren cac class
    DA la handle-type (eligible o Pass 1) - Phase 9d Part A, dong diem mu
    da ghi nhan tu Phase 9a (generator.py Pass 3 am tham bo qua, khong
    skips.append). Tra ve dict {'non_generic': int, 'generic': int}."""
    assembly_name = reflection_data["assemblyName"]
    known_assemblies = _DEFAULT_ASSEMBLIES | {assembly_name}
    _handle_types, eligible_full_names = compute_eligibility(reflection_data, known_assemblies)
    non_generic = 0
    generic = 0
    for cls in reflection_data["classes"]:
        if cls["fullName"] not in eligible_full_names:
            continue
        for m in cls["staticMethods"]:
            if m["isGeneric"]:
                generic += 1
            else:
                non_generic += 1
    return {"non_generic": non_generic, "generic": generic}


def _print_top(title, counter, top_n):
    print("\n%s" % title)
    for type_name, count in counter.most_common(top_n):
        print("  %5d  %s" % (count, type_name))


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="tkv-bind tally: dem tan suat kieu .NET khong map duoc, "
                     "tach instance (tren class eligible) vs static (tren class khong eligible)")
    parser.add_argument("--dll", required=True, help="Duong dan file .dll can phan xa")
    parser.add_argument("--top", type=int, default=10, help="So dong top can in (mac dinh 10)")
    args = parser.parse_args(argv)

    data = reflect_dll(args.dll)
    counters, n_eligible = tally(data)

    print("[tally] so class eligible (Pass 1, handle-type): %d" % n_eligible)
    _print_top("Top kieu tham so KHONG map duoc (instance method, tren class eligible):",
               counters["instance_param"], args.top)
    _print_top("Top kieu tham so KHONG map duoc (static method, tren class KHONG eligible):",
               counters["static_param"], args.top)
    _print_top("Top kieu tra ve KHONG map duoc (instance method):",
               counters["instance_return"], args.top)
    _print_top("Top kieu tra ve KHONG map duoc (static method):",
               counters["static_return"], args.top)
    return 0


if __name__ == "__main__":
    sys.exit(main())
