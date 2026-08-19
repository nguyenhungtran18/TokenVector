# -*- coding: utf-8 -*-
"""Nap dong cac module 'thu vien' (Phase 'tach tkvc.exe thanh core+plugin',
2026-08-12, xem docs/superpowers/specs/2026-08-12-tkvc-plugin-architecture-design.md).

2 CHE DO xac dinh thu muc plugin (discover_plugin_dir):
- Che do dev (`python tkv.py build ...`, chay truc tiep tu source, KHONG
  qua PyInstaller): thu muc plugin = 'compiler/il_features/' NHU HIEN TAI
  - khong doi hanh vi cay .py goc, chi doi CACH NAP (dong thay vi import
    cung trong il_codegen.py).
- Che do tkvc.exe dong goi (PyInstaller frozen, phat hien qua co chuan
  'sys.frozen'): thu muc plugin = 'il_features/' dat CANH file .exe dang
  chay (sys.executable).

load_plugins() quet moi file '*.py' trong thu muc do, import DONG qua
importlib.util (KHONG qua 'import' tinh cua Python - file thu vien
KHONG nam trong package 'compiler.il_features' nua sau khi build script
tach staging, xem build_tkvc.ps1). Moi file plugin TU chay cac lenh
register_* cua no luc duoc exec (side-effect, giong het co che import
cung TRUOC DAY - CHI doi CACH file duoc doc vao, khong doi code BEN
TRONG tung module thu vien).

QUAN TRONG (2 huong): trong che do dev, thu muc plugin VAN la
'compiler/il_features/' - noi CUNG chua ca nhom "core-dependency"
(list_type.py, string_feature.py, ...) LAN nhom "thu vien" (stdlib_math.py,
stdlib_re.py, ...). Mot so file "thu vien" (vd closures.py, dict_type.py)
CUNG duoc 1 file khac (il_codegen.py/tkv_compile.py) `from il_features.X
import ten` truc tiep (phu thuoc CORE that su, KHONG bi xoa o Task 11) -
2 duong nap (import tinh 'il_features.X' vs load_plugins() qua ten
SYNTHETIC '_tkv_plugin_X') KHONG tu dung chung 1 entry sys.modules nen
Python khong tu nhan ra chung la cung 1 module vat ly - du duong nao
chay TRUOC, duong con lai (neu khong xu ly) se exec lai file lan 2 ->
dang ky trung register_* -> ValueError tu il_dispatch's collision guard.
Xu ly CA 2 chieu:
  (a) truoc khi tu exec 1 file, kiem tra ca 2 ten ('_tkv_plugin_X' VA
      'il_features.X') da co trong sys.modules chua - co roi thi bo qua;
  (b) sau khi TU exec thanh cong duoi ten synthetic, GHI THEM 1 tham
      chieu sys.modules['il_features.X'] tro toi CUNG object module do -
      de 1 dong 'from il_features.X import ten' chay SAU load_plugins()
      (vd trong il_codegen.py) trung cache Python, khong exec lai.
Quan trong hon CA 2 diem tren: THU TU GOI load_plugins() so voi luc
import il_codegen.py. il_codegen.py's THAN file (khong phai khoi import
dau file) tu dang ky 1 vai LINE_PARSERS/FIRST_PASS_WALK... theo THU TU
CO Y NGHIA (vd 'method_call_stmt' PHAI dang ky SAU 'list_sort'/'list_
extend' - list.sort()/list.extend() phai duoc thu truoc method-call tong
quat, xem cascade trong _parse_block). Truoc Task 11, moi import
'il_features.X' (ca core-dependency lan thu-vien) deu nam o DAU
il_codegen.py, chay TRUOC than file - dam bao thu tu dung. Neu
load_plugins() chi duoc goi SAU khi 'from il_codegen import ...' (nhu
tkv_compile.py cu) thi than il_codegen.py da dang ky 'method_call_stmt'
XONG truoc khi cac thu vien (list_methods_batch2.py's 'list_sort'...)
duoc load_plugins() nap - dao NGUOC thu tu cascade, gay loi bien dich sai
(list.sort() bi method_call_stmt tong quat "nuot" truoc). VI VAY:
tkv_compile.py PHAI goi load_plugins() TRUOC dong 'from il_codegen import
...' (xem tkv_compile.py, Task 11)."""
import importlib.util
import os
import sys


def discover_plugin_dir():
    if getattr(sys, 'frozen', False):
        return os.path.join(os.path.dirname(sys.executable), 'il_features')
    # Che do dev: file nay nam tai 'compiler/plugin_loader.py', thu muc
    # plugin la 'compiler/il_features/' (cung thu muc cha).
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), 'il_features')


def load_plugins(plugin_dir=None):
    """Tra ve danh sach TEN FILE (khong duong dan) da nap thanh cong -
    rong neu thu muc khong ton tai (KHONG bao loi - chuong trinh dang
    bien dich co the khong dung builtin thu vien nao ca, thu muc rong/
    khong co la hop le).

    2-PASS (+retry) de xu ly THU TU phu thuoc giua cac file thu vien: 1
    file (vd file_io.py) co the co dong tinh 'import il_features.Y' HOAC
    'from il_features import Y as _y' o CAP MODULE tro toi 1 file thu
    vien KHAC (vd logging_feature.py) chua duoc nap (thu tu alphabet:
    file_io < logging_feature). Neu chi quet 1 luot theo thu tu bang chu
    cai, file_io.py se fail truoc khi logging_feature.py kip nap. Giai
    phap: bat rieng ImportError/ModuleNotFoundError (khac voi loi that
    trong noi dung file) trong luc exec_module, dua file loi vao hang
    doi retry, quet lai hang doi sau khi phan con lai da nap xong - lap
    toi da cho den khi 1 vong khong nap them duoc file nao (luc do moi
    bao loi that, tranh vong lap vo han neu la loi phu thuoc vong tron
    hoac module ngoai that su thieu)."""
    if plugin_dir is None:
        plugin_dir = discover_plugin_dir()
    if not os.path.isdir(plugin_dir):
        return []
    def _try_load(fname):
        """Tra ve (True, None) neu nap thanh cong / da nap roi (bo qua),
        (False, exc) neu that bai vi ImportError/ModuleNotFoundError (co
        the la loi phu thuoc thu tu, dang retry duoc). Cac loi khac duoc
        raise thang ra ngoai (loi that trong noi dung plugin, khong
        retry)."""
        fpath = os.path.join(plugin_dir, fname)
        stem = fname[:-3]
        mod_name = f'_tkv_plugin_{stem}'
        real_name = f'il_features.{stem}'
        if mod_name in sys.modules or real_name in sys.modules:
            # Da nap qua duong nay hoac qua 'from il_features.X import
            # ten' con lai trong il_codegen.py (phu thuoc CORE) - bo qua,
            # tranh exec lai lan 2 gay dang ky trung (xem docstring dau
            # file).
            return True, None
        spec = importlib.util.spec_from_file_location(mod_name, fpath)
        module = importlib.util.module_from_spec(spec)
        sys.modules[mod_name] = module
        try:
            spec.loader.exec_module(module)
        except ImportError as exc:
            # Co the la 1 dong 'import il_features.Y' HOAC 'from
            # il_features import Y as _y' tinh tro toi 1 file thu vien
            # KHAC chua duoc nap (van de thu tu) - ca 2 dang deu nem
            # ImportError (dang 2 cu the la 'cannot import name Y from
            # il_features' - ModuleNotFoundError la 1 subclass cua
            # ImportError nen bat chung 1 nhanh). Don dep entry nap do va
            # de vong ngoai quyet dinh retry hay bao loi that (neu sau
            # het cac vong retry van khong tien trien duoc, day moi la
            # loi that su - xem vong lap ben duoi).
            del sys.modules[mod_name]
            return False, exc
        except Exception as exc:
            del sys.modules[mod_name]
            raise ImportError(
                f"plugin_loader: nap thu vien '{fname}' that bai ({type(exc).__name__}: "
                f"{exc}) - file nam o {fpath!r}") from exc
        # (b) ghi them cache duoi ten goi THAT - xem docstring dau file
        # ('QUAN TRONG (2 huong)'), muc (b). CHI can dong nay: ca 'import
        # il_features.X as _x' lan 'from il_features import X as _x' deu
        # tu di qua nhanh du phong cua CPython import machinery dua tren
        # sys.modules['il_features.X'] (ModuleSpec cache-hit / fallback
        # trong _handle_fromlist) - KHONG can setattr len package cha
        # 'il_features', va KHONG duoc tu tao 1 package 'il_features' gia
        # (vi du __path__ = []) o day: lam vay se GHI DE len viec
        # CPython tu tao package 'il_features' THAT (voi __path__ dung)
        # khi lan dau 1 module CORE (vd list_type, duoc PyInstaller dong
        # bang that su ben trong 'il_features') duoc import - phat hien
        # qua thu nghiem thuc te: 1 package gia voi __path__ rong se lam
        # 'from il_features.list_type import ten' (module CORE, KHONG
        # qua plugin_loader) that bai vi tim submodule tren __path__ rong
        # thay vi qua frozen importer that.
        if real_name not in sys.modules:
            sys.modules[real_name] = module
        return True, None

    pending = [f for f in sorted(os.listdir(plugin_dir))
               if f.endswith('.py') and not f.startswith('_')]
    loaded = []
    last_exc = None
    while pending:
        next_pending = []
        progressed = False
        for fname in pending:
            ok, exc = _try_load(fname)
            if ok:
                loaded.append(fname)
                progressed = True
            else:
                last_exc = exc
                next_pending.append(fname)
        if not progressed:
            # Khong file nao trong vong nay nap duoc - loi phu thuoc that
            # su (module ngoai thieu, hoac vong tron), khong phai van de
            # thu tu nap - bao loi that, dung retry vo han.
            failed = ', '.join(next_pending)
            raise ImportError(
                f"plugin_loader: khong the nap cac thu vien sau (co the do "
                f"phu thuoc bi thieu/vong tron): {failed} - loi cuoi cung: "
                f"{type(last_exc).__name__}: {last_exc}") from last_exc
        pending = next_pending
    return loaded
