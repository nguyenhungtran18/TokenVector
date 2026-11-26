# -*- coding: utf-8 -*-
# Kiem tra vong train 1-lop: LOSS giam dan, khong co FAIL.
import re
out = ''
try:
    out = r.stdout
except NameError:
    pass
print('STDOUT TAIL:', out[-400:])
losses = [float(v) for v in re.findall(r'^LOSS\s+([0-9.eE+-]+)$', out, re.M)]
fails = re.findall(r'^[A-Z0-9 ]*FAIL[^\n]*$', out, re.M)
print('losses =', losses)
print('fails  =', fails)
mark_upd = re.findall(r'^MARK UPD (\d+)$', out, re.M)
print('updates =', mark_upd)
mark_fwd = re.findall(r'^MARK FWD\s+(\d+)$', out, re.M)
print('fwds =', mark_fwd)
ms = re.findall(r'^MS_STEP\s+([0-9.eE+-]+)$', out, re.M)
print('ms/step =', ms)
ok = (len(losses) == 3 and all(losses[i] > losses[i+1] for i in range(2))
      and not fails and len(mark_upd) == 6 and len(mark_fwd) == 6)
print('KET LUAN:', 'OK' if ok else 'XEM OUTPUT')
