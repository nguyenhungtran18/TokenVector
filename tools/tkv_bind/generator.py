# -*- coding: utf-8 -*-
"""Loc bang phan xa (reflection) tho thanh (1) van ban pragma .tkv hop
le va (2) danh sach ly do bi bo qua. KHONG sua compiler - chi sinh van
ban .tkv theo dung cu phap da co (test/sample_extern_class.tkv,
test/sample_extern_method.tkv).

QUAN TRONG: khong dung Python repr() de in chuoi - repr() cua chuoi
ASCII thuong cho ra single-quote ('Widget'), trong khi cu phap .tkv
pragma bat buoc double-quote ("Widget"). Dung _qs() thay the."""

from type_map import map_scalar, map_enum, map_dtype

_DEFAULT_ASSEMBLIES = frozenset({"mscorlib", "System", "System.Core"})


def _qs(s):
    """Double-quoted string, JSON/Python-dict-literal safe (khop dung
    kieu double-quote cua test/sample_extern_class.tkv, KHONG dung
    repr() vi repr() cho single-quote)."""
    escaped = s.replace("\\", "\\\\").replace('"', '\\"')
    return '"%s"' % escaped


def _short_name(full_name):
    return full_name.rsplit(".", 1)[-1].split("`")[0]


def _map_params(params, enums_info, known_assemblies, allow_object_type=True, handle_types=None):
    """Tra ve list dtype hoac None neu co 1 tham so khong map duoc. Phase
    9c: fallback sang map_enum() khi map_scalar tra None (co the la 1 kieu
    enum da duoc reflector.cs thu thap trong enums_info). Phase 9d Part B
    (2026-08-27): fallback tiep sang map_object()/map_type() khi map_enum
    cung tra None - System.Object/System.Type la 2 bucket unmapped-param
    LON NHAT con lai (do that: 199+63 instance/static cho Object, 53+38
    cho Type tren System.dll, xem roadmap doc).

    Critical 2 (final review Phase 9d Part B): 'allow_object_type=False'
    DUNG chuoi fallback LAI TRUOC map_object()/map_type() (chi con map_scalar
    -> map_enum) - dung cho duong nap CHI __tkv_extern_method__ (Pass 3,
    static method cua class KHONG phai handle-type) - compiler tu choi
    'object'/'type' tren pragma nay (xem tkv_compile.py's
    _validate_and_register_extern_method), nen sinh chung ra day se lam
    file .tkv output KHONG compile duoc. 3 diem goi con lai (ctor, instance
    method, static method CUA 1 handle-type - deu nap vao __tkv_extern_
    class__) giu allow_object_type=True (mac dinh, dung type_map.map_dtype
    - chuoi day du).

    Phase 9f (2026-08-27): 'handle_types' (dict full_name -> short_name, tu
    Pass 1) - fallback CUOI CUNG khi allow_object_type=False, SAU map_scalar/
    map_enum - dong gap Phase 9e (compiler da chap nhan handle-type lam
    param/return cho __tkv_extern_method__ tu commit ef4ff97, nhung
    generator.py chua tung thu map 1 tham so sang handle-type da biet cho
    duong nay). CHI ap dung o nhanh allow_object_type=False (Pass 3) - 3 diem
    goi con lai (allow_object_type=True, nap vao __tkv_extern_class__) DA
    map handle-type return qua kiem tra rieng 'ret in handle_types' (xem
    Pass 2), khong can sua o day."""
    out = []
    for p in params:
        if allow_object_type:
            dt = map_dtype(p, enums_info, known_assemblies, handle_types=handle_types)
        else:
            dt = map_scalar(p)
            if dt is None:
                dt = map_enum(p, enums_info, known_assemblies)
        # (Phase 9k, 2026-08-31): map_dtype()/map_array() CHI xu ly
        # handle_types cho cu phap MANG ('array[HandleType]', xem
        # map_array's docstring) - KHONG co nhanh rieng cho 1 BARE
        # handle-type lam tham so (vd 'My.Widget' don le, khong '[]').
        # Truoc day nhanh do CHI ton tai o branch allow_object_type=False
        # (Pass 3) - phat hien THIEU o branch True (Pass 2) qua regression
        # THAT (tkv_bind_generator_extern_method_handle_type_test.py) sau
        # khi Pass 3 doi sang allow_object_type=True (object/type gio ho
        # tro tren __tkv_extern_method__, xem tren). Ap dung CHUNG cho CA
        # 2 nhanh - AN TOAN (chi chay khi chuoi fallback truoc do da tra
        # None), khong lam thay doi ket qua cua bat ky truong hop da map
        # duoc tu truoc.
        if dt is None and handle_types is not None and p in handle_types:
            dt = handle_types[p]
        if dt is None:
            return None
        out.append(dt)
    return out


def generate(reflection_data):
    assembly_name = reflection_data["assemblyName"]
    enums_info = reflection_data.get("enums") or {}
    # Final review Phase 9c (Important #2): enum chi duoc bind neu assembly
    # cua no la assembly dang quet HOAC 1 assembly GAC mac dinh - dung LAI
    # _DEFAULT_ASSEMBLIES (khong tao hang so thu 2).
    known_assemblies = _DEFAULT_ASSEMBLIES | {assembly_name}
    skips = []
    handle_types = {}  # full_name -> short_name, chi cac class DA duoc nhan la handle-type
    class_entries = []
    method_entries = []

    # Pass 1: xac dinh class nao la handle-type. Phase 9b (2026-08-24):
    # thay vi doi hoi DUNG 1 ctor cong khai (truoc day: 2+ ctor -> bo qua
    # TOAN BO class, 253/... class tren System.dll bi mat trang), gio TU
    # CHON 1 ctor trong N cai - uu tien ctor co TAT CA tham so map scalar
    # duoc (bo qua ctor nao co tham so khong map duoc), trong cac ung vien
    # hop le do CHON ctor IT THAM SO NHAT (don gian/an toan nhat, it kha
    # nang side-effect an, de doan hanh vi nhat - KHONG co tieu chi "dung
    # nhat" tuyet doi trong .NET, day la 1 QUYET DINH THIET KE co chu dich,
    # khong phai suy luan chinh xac 100%). Class 0 ctor cong khai VAN bo
    # qua HOAN TOAN - khong co gi de chon (thuong la factory-pattern/
    # singleton, ngoai pham vi Phase 9b - xem so lieu that: 152/1.334 muc
    # 0-ctor tren System.dll, Phase 9b - khong tron voi tong 1.224 cua
    # Phase 9a, 2 con so tu 2 lan do khac nhau, xem roadmap doc).
    eligible = []
    for cls in reflection_data["classes"]:
        full_name = cls["fullName"]
        if cls["isGeneric"]:
            skips.append("%s: bo qua (class generic, chua ho tro)" % full_name)
            continue
        n_ctors = len(cls["ctors"])
        if n_ctors == 0:
            skips.append("%s: bo qua (co 0 constructor cong khai, can dung 1)" % full_name)
            continue
        scalar_ok_ctors = []
        for ctor in cls["ctors"]:
            mapped = _map_params(ctor["params"], enums_info, known_assemblies)
            if mapped is not None:
                scalar_ok_ctors.append(mapped)
        if not scalar_ok_ctors:
            skips.append(
                "%s: bo qua (co %d constructor cong khai, KHONG co ctor nao "
                "tham so deu map scalar duoc)" % (full_name, n_ctors))
            continue
        ctor_params = min(scalar_ok_ctors, key=len)
        short_name = _short_name(full_name)
        handle_types[full_name] = short_name
        eligible.append((cls, ctor_params, short_name))

    # Pass 2: sinh method cho tung handle-type (can biet toan bo
    # handle_types truoc, vi return-type chaining tham chieu class KHAC
    # cung duoc sinh trong lan chay nay).
    #
    # QUAN TRONG (final review Phase 9a, 2026-08-24, phat hien khi chay that
    # tren System.dll sau khi them consistency-check Critical 2 vao
    # tkv_compile.py): giong het seen_static_names cua Pass 3 (M2), khoa
    # dang ky THAT SU trong EXPR_METHOD_CODEGEN la ('extern_class',
    # method_name) - TOAN CUC, khong phan theo class. Dedup theo
    # seen_method_names (per-class, duoi day) chi bat duoc overload TRONG
    # CUNG 1 class; no KHONG bat duoc 2 class KHAC nhau cung co method trung
    # ten nhung KHAC void-ness (vd StringCollection.Add tra ve i32 vs 1
    # class khac co Add tra ve void that su) - truoc day 2 entry nay van
    # duoc sinh ra, compiler tkv_compile.py "thua ke" nham factory (Critical
    # 2), gio bi chan hop le boi TranspileError. seen_instance_method_voidness
    # PHAI la GLOBAL (ngoai vong lap 'for cls') de phat hien truoc khi sinh,
    # bo qua (skip) ben dang ky SAU thay vi de compiler tu choi ca file.
    seen_instance_method_voidness = {}
    for cls, ctor_params, short_name in eligible:
        full_name = cls["fullName"]
        methods = []
        seen_method_names = set()
        for m in cls["instanceMethods"]:
            if m["isGeneric"]:
                skips.append("%s.%s: bo qua (method generic, chua ho tro)" % (full_name, m["name"]))
                continue
            params = _map_params(m["params"], enums_info, known_assemblies, handle_types=handle_types)
            if params is None:
                skips.append("%s.%s: bo qua (tham so co kieu khong map duoc sang scalar)" % (full_name, m["name"]))
                continue
            ret = m["returns"]
            if ret == "System.Void":
                # Phase 9a (2026-08-24): compiler gio ho tro
                # 'returns':'void' cho extern_class method (xem Task 2 cua
                # plan nay) - khong con bo qua, sinh thang '"returns": "void"'.
                ret_dtype = "void"
            elif ret in handle_types:
                # CO Y: chap nhan return-type chaining sang BAT KY handle-type
                # class nao khac cung dang duoc sinh trong lan chay nay, khong
                # gioi han chi self-return (vd Factory.MakeWidget() -> Widget,
                # Factory != Widget). Day la pattern factory-method that su
                # trong .NET, va van sinh ra pragma .tkv hop le vi class kia
                # cung da/se duoc khai bao trong cung file output. Quyet dinh
                # nay GIU NGUYEN theo review Task 5 (khong thu hep lai).
                ret_dtype = handle_types[ret]
            else:
                # Minor 2 (final review Phase 9d Part B): nap vao __tkv_
                # extern_class__'s "methods" - dung chuoi fallback DAY DU
                # qua type_map.map_dtype (thay 4 dong map_scalar/map_enum/
                # map_object/map_type lap lai).
                ret_dtype = map_dtype(ret, enums_info, known_assemblies, handle_types=handle_types)
                if ret_dtype is None:
                    skips.append("%s.%s: bo qua (kieu tra ve khong map duoc sang scalar/handle-type)" % (full_name, m["name"]))
                    continue
            if m["name"] in seen_method_names:
                # QUAN TRONG: .NET cho phep overload (nhieu method cung ten
                # khac tham so). Pragma .tkv chi ho tro "1 chu ky = 1 lan"
                # (giong nguyen tac constructor o Pass 1) - neu sinh 2+ entry
                # cung ten trong cung class, compiler TokenVector reject ca
                # file voi loi "method 'X' khai TRUNG LAP". Chi giu signature
                # DAU TIEN gap, bo qua cac overload con lai.
                skips.append("%s.%s: bo qua (method overload trung ten, da chon signature dau tien)" % (full_name, m["name"]))
                continue
            _is_void = ret_dtype == "void"
            _prev_void = seen_instance_method_voidness.get(m["name"])
            if _prev_void is not None and _prev_void != _is_void:
                # Critical 2 (final review Phase 9a): 2 class KHAC nhau cung
                # co method trung ten nhung LECH void-ness - compiler se
                # reject ca file (TranspileError) neu ca 2 duoc sinh ra, nen
                # bo qua o day thay vi de sinh loi kho hieu o buoc dich.
                skips.append(
                    "%s.%s: bo qua (method trung ten toan cuc voi 1 method cung ten tren "
                    "class khac nhung KHAC void-ness - da chon signature dang ky dau tien gap)"
                    % (full_name, m["name"]))
                continue
            seen_instance_method_voidness[m["name"]] = _is_void
            seen_method_names.add(m["name"])
            methods.append((m["name"], params, ret_dtype))
        # Task 4 (Phase 9d Part A): sinh static method cua CHINH class
        # handle-type nay, dong diem mu Pass 3 cu (truoc day am tham bo
        # qua TOAN BO static method cua class da la handle-type, khong co
        # skip report). Dedup theo ten CUC BO trong 1 class (bien 'seen'
        # rieng, KHONG dung seen_static_names toan cuc cua Pass 3 - khac
        # namespace: day la static method GAN VAO 1 class __tkv_extern_class__
        # cu the, khong phai __tkv_extern_method__ toan cuc).
        static_methods = []
        seen_static_method_names = set()
        for m in cls["staticMethods"]:
            if m["isGeneric"]:
                skips.append("%s.%s: bo qua (method generic, chua ho tro)" % (full_name, m["name"]))
                continue
            params = _map_params(m["params"], enums_info, known_assemblies, handle_types=handle_types)
            if params is None:
                skips.append("%s.%s: bo qua (tham so co kieu khong map duoc sang scalar)" % (full_name, m["name"]))
                continue
            if m["returns"] == "System.Void":
                ret_dtype = "void"
            else:
                # Minor 2 (final review Phase 9d Part B): nap vao __tkv_
                # extern_class__'s "static_methods" - chuoi fallback DAY DU
                # (giong nhanh instance method o tren), qua type_map.map_dtype.
                ret_dtype = map_dtype(m["returns"], enums_info, known_assemblies, handle_types=handle_types)
                if ret_dtype is None:
                    skips.append("%s.%s: bo qua (kieu tra ve khong map duoc sang scalar)" % (full_name, m["name"]))
                    continue
            if m["name"] in seen_method_names:
                # Compiler tu choi ca file neu 1 class co static method TRUNG
                # TEN voi 1 instance method DA khai trong "methods" cua CHINH
                # class do (vd EventLog.WriteEntry co CA ban instance LAN
                # static, phat hien khi chay that tren System.dll) - bo qua
                # o day thay vi de loi kho hieu o buoc dich.
                skips.append(
                    "%s.%s: bo qua (static method trung ten voi instance method cung ten "
                    "trong cung class, da giu instance method)" % (full_name, m["name"]))
                continue
            if m["name"] in seen_static_method_names:
                skips.append(
                    "%s.%s: bo qua (static method overload trung ten trong cung class, "
                    "da chon signature dau tien gap)" % (full_name, m["name"]))
                continue
            seen_static_method_names.add(m["name"])
            static_methods.append((m["name"], params, ret_dtype))
        class_entries.append((short_name, assembly_name, full_name, ctor_params, methods, static_methods))

    # Pass 3: cac static method tren class KHONG phai handle-type ->
    # __tkv_extern_method__ doc lap.
    # QUAN TRONG (M2, fast-follow theo roadmap 2026-08-20, phat hien khi
    # chay that tren System.dll): seen_static_names phai la GLOBAL, khai bao
    # BEN NGOAI vong lap per-class ben duoi. __tkv_extern_method__["name"]
    # duoc compiler dang ky vao 1 namespace TOAN CUC (register_expr_builtin,
    # xem tkv_compile.py:1509-1512) - neu 2 class KHAC nhau (vd
    # System.Diagnostics.Debug va System.Diagnostics.Trace) cung co static
    # method ten "Flush", ca 2 deu bi sinh ra __tkv_extern_method__ trung
    # ten neu chi dedup per-class -> compiler reject ca file voi ValueError.
    # Day KHAC voi dedup trong Pass 2 (line 108), vi Pass 2 dedup theo
    # method-cua-1-class (namespace la method cua handle-type instance,
    # khong global).
    seen_static_names = set()
    for cls in reflection_data["classes"]:
        full_name = cls["fullName"]
        if cls["isGeneric"]:
            continue
        if full_name in handle_types:
            # Task 4 (Phase 9d Part A): static method cua class DA la
            # handle-type gio duoc sinh vao "static_methods" cua CHINH
            # entry class do trong Pass 2 (xem vong lap 'eligible' o tren) -
            # khong con am tham bo qua o day nua, va cung KHONG lap lai
            # duoi dang __tkv_extern_method__ doc lap (se trung namespace).
            continue
        for m in cls["staticMethods"]:
            if m["isGeneric"]:
                skips.append("%s.%s: bo qua (method generic, chua ho tro)" % (full_name, m["name"]))
                continue
            # (Phase 9k, 2026-08-31): truoc day allow_object_type=False vi
            # compiler tu choi 'object'/'type' tren __tkv_extern_method__
            # (_validate_and_register_extern_method) - da go bo chan do
            # (xem tkv_compile.py, Phase 9k) sau khi xac nhan ha tang
            # codegen da san sang tu Phase 9d Part B/9e. Phat hien qua
            # tkv-bind chay THAT tren NuGet Newtonsoft.Json: JsonConvert.
            # SerializeObject(object)/DeserializeObject(...)->object bi bo
            # qua vi gioi han cu. Bat allow_object_type=True.
            params = _map_params(m["params"], enums_info, known_assemblies,
                                  allow_object_type=True, handle_types=handle_types)
            if params is None:
                skips.append("%s.%s: bo qua (tham so co kieu khong map duoc sang scalar)" % (full_name, m["name"]))
                continue
            if m["returns"] == "System.Void":
                # Phase 9a: mirror Pass 2 - void gio la 1 dtype hop le rieng,
                # khong con gop chung voi "khong map duoc sang scalar".
                ret_dtype = "void"
            elif m["returns"] in handle_types:
                # Phase 9f (2026-08-27): mirror Pass 2's return-type chaining
                # (line ~147) - compiler da chap nhan handle-type return cho
                # __tkv_extern_method__ tu Phase 9e (ef4ff97).
                ret_dtype = handle_types[m["returns"]]
            else:
                # (Phase 9k, 2026-08-31): compiler khong con tu choi 'object'/
                # 'type' tren __tkv_extern_method__ nua (xem tkv_compile.py,
                # Phase 9k) - dung LAI map_dtype() (chuoi fallback DAY DU
                # scalar->enum->object->type->array) thay vi chuoi rieng cu
                # chi scalar->enum, mirror dung Pass 2 da lam tu truoc.
                ret_dtype = map_dtype(m["returns"], enums_info, known_assemblies)
                if ret_dtype is None:
                    skips.append("%s.%s: bo qua (kieu tra ve khong map duoc sang scalar)" % (full_name, m["name"]))
                    continue
            if m["name"] in seen_static_names:
                # M2: co the la overload trong CUNG 1 class, HOAC trung ten
                # voi static method cua 1 class KHAC (cross-class collision -
                # ly do that su gay loi tren System.dll, xem Task 4 fix
                # report). Ghi ro "khac class" de nguoi doc skip report phan
                # biet duoc voi truong hop overload thong thuong trong Pass 2.
                skips.append(
                    "%s.%s: bo qua (method trung ten toan cuc voi static method cung ten tren class khac "
                    "hoac overload trong cung class, da chon signature dau tien gap)" % (full_name, m["name"]))
                continue
            seen_static_names.add(m["name"])
            method_entries.append((m["name"], assembly_name, full_name, params, ret_dtype))

    pragma_text = _render(class_entries, method_entries, assembly_name)
    return pragma_text, skips


def _render(class_entries, method_entries, assembly_name=None):
    parts = []
    if (class_entries or method_entries) and assembly_name is not None \
            and assembly_name not in _DEFAULT_ASSEMBLIES:
        parts.append('__tkv_extern_assembly__ = (%s, None, None)' % _qs(assembly_name))
    if class_entries:
        lines = ["__tkv_extern_class__ = ["]
        for short_name, assembly_name, full_name, ctor_params, methods, static_methods in class_entries:
            lines.append("    {")
            lines.append('        "name": %s, "assembly": %s, "class": %s,' % (
                _qs(short_name), _qs(assembly_name), _qs(full_name)))
            lines.append('        "ctor": %s,' % _py_list(ctor_params))
            lines.append('        "methods": [')
            for m_name, m_params, m_ret in methods:
                lines.append('            {"name": %s, "params": %s, "returns": %s},' % (
                    _qs(m_name), _py_list(m_params), _qs(m_ret)))
            lines.append("        ],")
            if static_methods:
                lines.append('        "static_methods": [')
                for m_name, m_params, m_ret in static_methods:
                    lines.append('            {"name": %s, "params": %s, "returns": %s},' % (
                        _qs(m_name), _py_list(m_params), _qs(m_ret)))
                lines.append("        ],")
            lines.append("    },")
        lines.append("]")
        parts.append("\n".join(lines))
    if method_entries:
        lines = ["__tkv_extern_method__ = ["]
        for m_name, assembly_name, full_name, params, ret in method_entries:
            lines.append('    {"name": %s, "assembly": %s, "class": %s,' % (
                _qs(m_name), _qs(assembly_name), _qs(full_name)))
            lines.append('     "method": %s, "params": %s, "returns": %s},' % (
                _qs(m_name), _py_list(params), _qs(ret)))
        lines.append("]")
        parts.append("\n".join(lines))
    return "\n\n".join(parts)


def _py_list(items):
    return "[" + ", ".join(_qs(i) for i in items) + "]"
