$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
function Esc($f) {
    $t = Get-Content $f -Raw
    $t = $t.Replace("`r`n", "`n")
    $t = $t.Replace('\', '\\')
    $t = $t.Replace("`n", '\n')
    $t = $t.Replace('"', '\"')
    return $t
}
$a = Esc '_l3_pm.ptx'
$b = Esc '_l3_cb.ptx'
$c = Esc '_l3_dx.ptx'
$tpl = @'

def loss3_init() -> "i64":
    PA = b"__PA__"
    FA = b"loss_pm\x00"
    pb1 = alloc_bytes(len(PA) + 1)
    kk: "i32" = 0
    while kk < len(PA):
        wh: "i64" = write_u8(pb1, kk, PA[kk])
        kk = kk + 1
    wh = write_u8(pb1, kk, 0)
    mc = alloc_bytes(8)
    rc: "i32" = cu_module_load(mc, pb1)
    if rc != 0:
        print("L3A MOD FAIL", rc)
        return 0
    mod: "i64" = read_i64(mc, 0)
    na = alloc_bytes(len(FA))
    kk = 0
    while kk < len(FA):
        wh = write_u8(na, kk, FA[kk])
        kk = kk + 1
    fca = alloc_bytes(8)
    rc = cu_module_fn(fca, mod, na)
    if rc != 0:
        print("L3A FN FAIL", rc)
        return 0
    fa: "i64" = read_i64(fca, 0)
    PB = b"__PB__"
    FB = b"loss_cb\x00"
    pb2 = alloc_bytes(len(PB) + 1)
    kk = 0
    while kk < len(PB):
        wh = write_u8(pb2, kk, PB[kk])
        kk = kk + 1
    wh = write_u8(pb2, kk, 0)
    mc2 = alloc_bytes(8)
    rc = cu_module_load(mc2, pb2)
    if rc != 0:
        print("L3B MOD FAIL", rc)
        return 0
    mod2: "i64" = read_i64(mc2, 0)
    nbn = alloc_bytes(len(FB))
    kk = 0
    while kk < len(FB):
        wh = write_u8(nbn, kk, FB[kk])
        kk = kk + 1
    fcb = alloc_bytes(8)
    rc = cu_module_fn(fcb, mod2, nbn)
    if rc != 0:
        print("L3B FN FAIL", rc)
        return 0
    fb: "i64" = read_i64(fcb, 0)
    PC = b"__PC__"
    FC = b"loss_dx\x00"
    pb3 = alloc_bytes(len(PC) + 1)
    kk = 0
    while kk < len(PC):
        wh = write_u8(pb3, kk, PC[kk])
        kk = kk + 1
    wh = write_u8(pb3, kk, 0)
    mc3 = alloc_bytes(8)
    rc = cu_module_load(mc3, pb3)
    if rc != 0:
        print("L3C MOD FAIL", rc)
        return 0
    mod3: "i64" = read_i64(mc3, 0)
    ncn = alloc_bytes(len(FC))
    kk = 0
    while kk < len(FC):
        wh = write_u8(ncn, kk, FC[kk])
        kk = kk + 1
    fcc = alloc_bytes(8)
    rc = cu_module_fn(fcc, mod3, ncn)
    if rc != 0:
        print("L3C FN FAIL", rc)
        return 0
    fc: "i64" = read_i64(fcc, 0)
    hb3 = alloc_bytes(24)
    wh = write_i64(hb3, 0, fa)
    wh = write_i64(hb3, 8, fb)
    wh = write_i64(hb3, 16, fc)
    return hb3

def l3_launch(fn: "i64", gx: "i32", gy: "i32", bx: "i32", p1: "i64", p2: "i64", p3: "i64", p4: "i64", p5: "i64", p6: "i64", p7: "i64") -> "i32":
    a1 = alloc_bytes(8)
    wh: "i64" = write_i64(a1, 0, p1)
    a2 = alloc_bytes(8)
    wh = write_i64(a2, 0, p2)
    a3 = alloc_bytes(8)
    wh = write_i64(a3, 0, p3)
    a4 = alloc_bytes(8)
    wh = write_i64(a4, 0, p4)
    a5 = alloc_bytes(8)
    wh = write_i64(a5, 0, p5)
    a6 = alloc_bytes(8)
    wh = write_i64(a6, 0, p6)
    a7 = alloc_bytes(8)
    wh = write_i64(a7, 0, p7)
    pl = alloc_bytes(56)
    wh = write_i64(pl, 0, a1)
    wh = write_i64(pl, 8, a2)
    wh = write_i64(pl, 16, a3)
    wh = write_i64(pl, 24, a4)
    wh = write_i64(pl, 32, a5)
    wh = write_i64(pl, 40, a6)
    wh = write_i64(pl, 48, a7)
    rc: "i32" = cu_launch(fn, gx, gy, 1, bx, 1, 1, 0, 0, pl, 0)
    if rc != 0:
        print("L3 LAUNCH FAIL", rc)
    return rc

def loss3_fwd(h: "i64", lg: "i64", pk: "i64", dl: "i64", ls: "i64", pm: "i64", ps: "i64", gm: "i64", gi: "i64", tn: "i32", nb: "i32") -> "i32":
    fa: "i64" = read_i64(h, 0)
    fb: "i64" = read_i64(h, 8)
    fc: "i64" = read_i64(h, 16)
    zz: "i64" = 0
    rb: "i32" = 128
    gy: "i32" = tn // rb
    rc: "i32" = l3_launch(fa, nb, gy, rb, lg, pm, ps, pk, zz, zz, zz)
    if rc != 0:
        return 1
    rc = l3_launch(fb, 1, 1, tn, pm, ps, lg, pk, ls, gm, gi)
    if rc != 0:
        return 1
    rc = l3_launch(fc, nb, gy, rb, lg, gm, gi, pk, dl, zz, zz)
    if rc != 0:
        return 1
    return 0
'@
$out = $tpl.Replace('__PA__', $a).Replace('__PB__', $b).Replace('__PC__', $c)
Set-Content -Path '_loss3_snippet.tkv' -Value $out -NoNewline -Encoding UTF8
"snippet chars=$($out.Length)"
"PA head=$($out.Substring($out.IndexOf('PA = b"'), 90))"
