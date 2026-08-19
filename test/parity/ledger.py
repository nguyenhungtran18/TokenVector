# -*- coding: utf-8 -*-
"""So lech test/parity/ledger.toml (moc 8, buoc 1.3 cua ke hoach).

Moi muc ghim HAI CHIEU: ca `open` phai VAN lech, va lech DUNG KIEU da
ghi (`kind`) - tu nhien het lech thi test do (bao "co ve da sua, hay doi
status"), lech kieu KHAC cung do. Nho vay so giu duoc bo test xanh ma
khong cho loi da biet am tham bien hinh - xem verify_entry().

Doc bang `tomllib` co san tu Python 3.11 (chi doc). GHI thi tu viet -
KHONG co writer TOML trong stdlib, va schema o day don gian (list cac
bang phang [[entry]], khong long nhau) nen khong dang mot dependency
moi chi vi viec nay.
"""
import re
import sys
import tomllib
from pathlib import Path

LEDGER_PATH = Path(__file__).parent / 'ledger.toml'


def load(path=LEDGER_PATH):
    if not path.exists():
        return []
    with open(path, 'rb') as fh:
        data = tomllib.load(fh)
    return data.get('entry', [])


def _toml_str(s):
    """Chuoi TOML basic 1 dong - escape backslash/nhay kep/xuong dong."""
    s = s.replace('\\', '\\\\').replace('"', '\\"')
    s = s.replace('\r\n', '\\n').replace('\n', '\\n').replace('\t', '\\t')
    return '"%s"' % s


def _toml_multiline(s):
    """Chuoi TOML basic 3-nhay-kep, giu nguyen xuong dong that (de code
    nguon doc duoc khi mo file bang mat thuong)."""
    body = s.replace('\\', '\\\\')
    # TOML cam """ ben trong """...""" - tach bang zero-width neu gap
    # (cuc hiem trong code sinh ra, nhung phai an toan).
    body = body.replace('"""', '""\\"')
    return '"""\n%s"""' % body


def save(entries, path=LEDGER_PATH):
    lines = [
        '# So lech CodeGraph/TokenVector - SINH + GHI BOI test/parity/*.',
        '# KHONG sua tay gia tri python_value/tokenvector_value/kind -',
        '# doi status thi sua status, con lai de fuzz.py/ledger.py ghi.',
        '',
    ]
    for e in entries:
        lines.append('[[entry]]')
        for key in ('id', 'kind', 'severity', 'status', 'site',
                    'discovered', 'templates'):
            if key not in e:
                continue
            v = e[key]
            if isinstance(v, list):
                lines.append('%s = [%s]' % (
                    key, ', '.join(_toml_str(x) for x in v)))
            else:
                lines.append('%s = %s' % (key, _toml_str(str(v))))
        for key in ('python_value', 'tokenvector_value', 'note'):
            if key in e and e[key] is not None:
                lines.append('%s = %s' % (key, _toml_str(str(e[key]))))
        if 'repro' in e:
            lines.append('repro = %s' % _toml_multiline(e['repro']))
        lines.append('')
    path.write_text('\n'.join(lines), encoding='utf-8')


def _norm(source):
    """Chu ky tho de khu trung - bo khoang trang thua, giu cau truc."""
    return re.sub(r'\s+', ' ', source).strip()


def next_id(entries):
    nums = [int(m.group(1)) for e in entries
            for m in [re.match(r'P(\d+)$', e.get('id', ''))] if m]
    return 'P%03d' % (max(nums, default=0) + 1)


def add_entry(entries, kind, detail, source, templates, site,
              discovered, severity=None):
    """Them 1 muc MOI neu chua co repro TUONG DUONG (khu trung tho).
    Tra ve entry moi hoac None neu la trung lap."""
    norm = _norm(source)
    for e in entries:
        if _norm(e.get('repro', '')) == norm:
            return None
    if severity is None:
        severity = ('silent' if kind in ('value_mismatch', 'tkv_silently_succeeds')
                    else 'loud')
    entry = {
        'id': next_id(entries),
        'kind': kind,
        'severity': severity,
        'status': 'open',
        'site': site,
        'discovered': discovered,
        'templates': templates,
        'note': detail,
        'repro': source,
    }
    entries.append(entry)
    return entry


def verify_entry(entry):
    """Chay lai 1 muc, tra (van_lech: bool, kind_thuc_te). Muc 'open'
    phai van_lech=True VA kind_thuc_te == entry['kind']."""
    sys.path.insert(0, str(Path(__file__).parent))
    import arbiter as A
    kind, detail, py, tkv = A.probe(entry['repro'], tag='verify_%s' % entry['id'])
    return kind == entry['kind'], kind


if __name__ == '__main__':
    entries = load()
    print('%d muc trong so:' % len(entries))
    for e in entries:
        print(' ', e['id'], e['kind'], e['status'], '-', e.get('note', '')[:70])
