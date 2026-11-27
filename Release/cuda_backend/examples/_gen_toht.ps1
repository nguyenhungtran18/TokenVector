$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$t=Get-Content '_toht.ptx' -Raw
$t=$t.Replace("`r`n","`n")
$t=$t.Replace('\','\\')
$t=$t.Replace("`n",'\n')
$t=$t.Replace('"','\"')
$tpl=@'

def toht_init() -> "i64":
    PTX = b"__PTX__"
    FNS = b"toht_kernel\x00"
    pb = alloc_bytes(len(PTX) + 1)
    kk: "i32" = 0
    while kk < len(PTX):
        wh: "i64" = write_u8(pb, kk, PTX[kk])
        kk = kk + 1
    wh = write_u8(pb, kk, 0)
    mc = alloc_bytes(8)
    rc: "i32" = cu_module_load(mc, pb)
    if rc != 0:
        print("TOHT MOD FAIL", rc)
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
        print("TOHT FN FAIL", rc)
        return 0
    fnh: "i64" = read_i64(fc, 0)
    return fnh

def toht(fnh: "i64", src: "i64", dst: "i64", n: "i32", f: "i32") -> "i32":
    a0 = alloc_bytes(8)
    wh: "i64" = write_i64(a0, 0, src)
    a1 = alloc_bytes(8)
    wh = write_i64(a1, 0, dst)
    a2 = alloc_bytes(4)
    wh = write_i32(a2, 0, n)
    a3 = alloc_bytes(4)
    wh = write_i32(a3, 0, f)
    pl = alloc_bytes(32)
    wh = write_i64(pl, 0, a0)
    wh = write_i64(pl, 8, a1)
    wh = write_i64(pl, 16, a2)
    wh = write_i64(pl, 24, a3)
    g: "i32" = (n + 255) >> 8
    rc: "i32" = cu_launch(fnh, g, 1, 1, 256, 1, 1, 0, 0, pl, 0)
    if rc != 0:
        print("TOHT LAUNCH FAIL", rc)
    return rc

'@
$out=$tpl.Replace('__PTX__',$t)
Set-Content '_toht_snippet.tkv' -Value $out -NoNewline -Encoding UTF8
Write-Output ('snippet chars='+$out.Length)
