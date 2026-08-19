# -*- coding: utf-8 -*-
"""Nhan phan loai cho tung test — dinh nghia DUY NHAT, dung boi run_tests.py.

Muc dich: phan biet "test do vi TokenVector sai" voi "test do vi may nay
thieu thu gi". Truoc file nay, ca hai deu hien ra nhu nhau va lan vao nhau,
nen so 'xanh' khong noi len dieu gi.

Quy tac: mot test CHI duoc gan nhan khi da CHUNG MINH duoc no do vi moi
truong — chay lai tren ban chua sua va thay do y het. Gan nhan de che mot
loi that la tu lua minh; do dung la loai 'false-green' ma
PARITY_GAPS_2026-08-04.md muc 1 canh bao.

Nhan:
  net    — can Internet that.
  native — can thu vien native khong co san (sqlite3.dll).
  repo   — can cay repo DAY DU (manifest CodeGraph tro ra ngoai TokenVector);
           khong chay duoc trong git worktree vi worktree thieu file khong
           duoc theo doi.
  slow   — chay lau, van tinh la bat buoc; chi de loc khi can nhanh.
"""

# ten file (khong duong dan) -> (tap nhan, ly do doc duoc)
TAGS = {
    'db_test.py': (
        {'native'},
        "can sqlite3.dll; khong co trong PATH tren may nay",
    ),
    'extern_method_test.py': (
        {'native'},
        "goi System.Math::Pow qua __tkv_extern_method__/ilasm - can .NET "
        "Framework GAC (mscorlib/System) co san tren may build",
    ),
    'group8_expr_test.py': (
        {'native', 'net'},
        "can sqlite3.dll VA http_post ra Internet",
    ),
    'http_get_test.py': (
        {'net'},
        "goi https://example.com that",
    ),
    'http_request_test.py': (
        {'net'},
        "goi HTTP that",
    ),
    'expr_builtin_compose_test.py': (
        {'net'},
        "co nhanh http_get that",
    ),
    'pytok_test.py': (
        {'repo'},
        "doc CodeGraph/graph/code_graph_manifest.txt tro ra ngoai TokenVector; "
        "worktree khong co cac file do",
    ),
    'typegraph_test.py': (
        {'repo'},
        "nhu pytok_test — can cay repo day du",
    ),
}

# Test cham (giay). Chi de bao cao, khong tu dong bo qua.
SLOW_SECONDS = 30.0


def tags_for(name):
    """Tap nhan cua 1 test (rong neu khong co nhan)."""
    entry = TAGS.get(name)
    return entry[0] if entry else set()


def reason_for(name):
    """Ly do doc duoc, hoac chuoi rong."""
    entry = TAGS.get(name)
    return entry[1] if entry else ''
