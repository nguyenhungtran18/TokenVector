# -*- coding: utf-8 -*-
import re, math
out = ''
try:
    out = r.stdout
except NameError:
    pass
print('STDOUT TAIL:', out[-400:])
losses = re.findall(r'^LOSS\s+([0-9.eE+-]+)$', out, re.M)
fails = re.findall(r'^[A-Z0-9 ]*FAIL[^\n]*$', out, re.M)
fwds = re.findall(r'^MARK FWD\s+(\d+)$', out, re.M)
upds = re.findall(r'^MARK UPD\\s+(\\d+)$', out, re.M)
bwds = re.findall(r'^MARK BWD\s+(\d+)$', out, re.M)
print('losses =', losses)
print('fails  =', fails)
print('fwds   =', fwds, 'bwds =', bwds)
ok = (len(losses) == 2 and all(math.isfinite(float(v)) for v in losses)
      and not fails and len(fwds) == 2 and len(bwds) == 2 and len(upds) == 2)
print('KET LUAN:', 'OK' if ok else 'XEM OUTPUT')
