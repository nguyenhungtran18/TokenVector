$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$t=Get-Content '_adamw.ptx' -Raw
$t=$t.Replace("`r`n","`n")
$t=$t.Replace('\','\\')
$t=$t.Replace("`n",'\n')
$t=$t.Replace('"','\"')
$tpl=@'

def adamw_init() -> "i64":
    PTX = b"__PTX__"
    FNS = b"adamw_kernel\x00"
    pb = alloc_bytes(len(PTX) + 1)
    kk: "i32" = 0
    while kk < len(PTX):
        wh: "i64" = write_u8(pb, kk, PTX[kk])
        kk = kk + 1
    wh = write_u8(pb, kk, 0)
    mc = alloc_bytes(8)
    rc: "i32" = cu_module_load(mc, pb)
    if rc != 0:
        print("ADAMW MOD FAIL", rc)
        return 0
    mod: "i64" = read_i64(mc, 0)
    nb = alloc_bytes(len(FNS))
    kk = 0
    while kk < len(FNS):
        wh = write_u8(nb, kk, FNS[kk])
        kk = kk + 1
    fc = alloc_bytes(8)
    rc = cu_module_fn(fc, mod, nb)
    if rc != 0:
        print("ADAMW FN FAIL", rc)
        return 0
    fnh: "i64" = read_i64(fc, 0)
    return fnh

def adamw_update(fnh: "i64", w: "i64", g: "i64", m: "i64", v: "i64", n: "i32", lr: "f32", bc1: "f32", bc2: "f32", wd: "f32") -> "i32":
    a0 = alloc_bytes(8)
    wh: "i64" = write_i64(a0, 0, w)
    a1 = alloc_bytes(8)
    wh = write_i64(a1, 0, g)
    a2 = alloc_bytes(8)
    wh = write_i64(a2, 0, m)
    a3 = alloc_bytes(8)
    wh = write_i64(a3, 0, v)
    a4 = alloc_bytes(4)
    wh = write_f32(a4, 0, lr)
    a5 = alloc_bytes(4)
    wh = write_f32(a5, 0, bc1)
    a6 = alloc_bytes(4)
    wh = write_f32(a6, 0, bc2)
    a7 = alloc_bytes(4)
    wh = write_f32(a7, 0, wd)
    a8 = alloc_bytes(4)
    wh = write_i32(a8, 0, n)
    pl = alloc_bytes(72)
    wh = write_i64(pl, 0, a0)
    wh = write_i64(pl, 8, a1)
    wh = write_i64(pl, 16, a2)
    wh = write_i64(pl, 24, a3)
    wh = write_i64(pl, 32, a4)
    wh = write_i64(pl, 40, a5)
    wh = write_i64(pl, 48, a6)
    wh = write_i64(pl, 56, a7)
    wh = write_i64(pl, 64, a8)
    gr: "i32" = (n + 255) >> 8
    rc: "i32" = cu_launch(fnh, gr, 1, 1, 256, 1, 1, 0, 0, pl, 0)
    if rc != 0:
        print("ADAMW LAUNCH FAIL", rc)
    return rc

'@
$out=$tpl.Replace('__PTX__',$t)
Set-Content '_adamw_snippet.tkv' -Value $out -NoNewline -Encoding UTF8
Write-Output ('snippet chars='+$out.Length)
