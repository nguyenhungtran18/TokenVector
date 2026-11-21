#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""tkv_cuda.py -- prototype "CUDA kernel backend" cho TokenVector.

Y MOT: chung minh rang co the them kha nang dinh nghia CUDA kernel ngay trong
file .tkv ma KHONG sua compiler. Cong cu nay la 1 source-to-source backend:

    .tkv (co kernel duoc danh dau)  --tkv_cuda.py-->  .cu + glue .tkv

Cac kernel duoc viet bang Python/tokenvector-like syntax, duoc parse bang
`ast` cua Python (nen khong can parser moi), roi sinh ra:

  * <stem>.cuda.cu     : __global__ kernel + extern "C" launcher (mot lan)
  * <stem>.cuda.tkv    : __tkv_extern_pinvoke__ + wrapperfunctions
  * <stem>.cuda.build.sh : lenh nvcc (de chay trong Colab)
  * <stem>.with_cuda.tkv : file .tkv gop (kernel da duoc thay bang glue)

CHU Y: day la PROTOTYPE. Khong phai compiler backend chinh thuc; khong co
nvcc tren may Windows nay nen chi kiem tra duoc phan sinh ma (test included).
Gioi han: scalar f32/i32/i64, con tro f32/i32, if/assign++/so sanh, khong
struct, khong callback, khong dynamic parallelism.
"""

from __future__ import annotations

import argparse
import ast
import os
import re
import sys
from dataclasses import dataclass
from typing import Dict, List, Optional

MARKER = re.compile(r"^\s*#\s*@tkv\.cuda_kernel\b(.*)$")
OPTION = re.compile(r'([A-Za-z_]\w*)\s*=\s*"([^"]*)"')

DTYPE_TO_C = {
    "f32": "float",
    "f64": "double",
    "i32": "int",
    "i64": "long long",
    "void": "void",
}


def ann_of(arg: ast.arg) -> str:
    """TokenVector viet annotation dang chuoi: x: "ptr[f32]"."""
    if arg.annotation is None:
        return "f32"
    if isinstance(arg.annotation, ast.Constant) and isinstance(arg.annotation.value, str):
        return arg.annotation.value
    return ast.unparse(arg.annotation)


def _base_type(ann: str) -> str:
    """'ptr[f32]' -> 'f32'; 'f32' -> 'f32'."""
    ann = ann.strip()
    m = re.fullmatch(r"ptr\[(.+)\]", ann)
    return m.group(1) if m else ann


def _is_ptr(ann: str) -> bool:
    return bool(re.fullmatch(r"ptr\[.+\]", ann.strip()))


@dataclass
class Kernel:
    name: str
    args: List[ast.arg]
    body: List[ast.stmt]
    grid: str
    block: str
    line_start: int
    line_end: int


def parse_kernels(source: str) -> List[Kernel]:
    lines = source.splitlines()
    out: List[Kernel] = []
    i = 0
    while i < len(lines):
        m = MARKER.match(lines[i])
        if not m:
            i += 1
            continue
        opts = dict(OPTION.findall(m.group(1)))
        j = i + 1
        while j < len(lines) and not lines[j].lstrip().startswith("def "):
            j += 1
        if j >= len(lines):
            raise SyntaxError("tkv.cuda_kernel o dong %d khong co 'def' ngay sau" % (i + 1))
        k = j + 1
        while k < len(lines) and (not lines[k].strip() or lines[k].startswith("    ")):
            k += 1
        tree = ast.parse("\n".join(lines[j:k]))
        fn = tree.body[0]
        if not isinstance(fn, ast.FunctionDef):
            raise SyntaxError("kernel phai la 'def'")
        out.append(
            Kernel(
                name=fn.name,
                args=fn.args.args,
                body=fn.body,
                grid=opts.get("grid", "(n + 255) // 256"),
                block=opts.get("block", "256"),
                line_start=i,
                line_end=k,
            )
        )
        i = k
    return out


class CGenerator:
    """Dịch một tập lệnh Python (AST) sang thân kernel C."""

    def __init__(self, kernel: Kernel):
        self.k = kernel
        self.types: Dict[str, str] = {}
        for a in kernel.args:
            ann = ann_of(a)
            self.types[a.arg] = _base_type(ann)
        self.written: set = set()  # param duoc ghi -> khong const
        self._scan_writes(kernel.body)
        self.lines: List[str] = []

    def _scan_writes(self, body):
        for node in ast.walk(ast.Module(body=body, type_ignores=[])):
            if isinstance(node, (ast.Assign, ast.AugAssign)):
                targets = node.targets if isinstance(node, ast.Assign) else [node.target]
                for t in targets:
                    if isinstance(t, ast.Subscript) and isinstance(t.value, ast.Name):
                        self.written.add(t.value.id)

    # ---- suy kieu don gian -------------------------------------------------
    def expr_type(self, node: ast.AST) -> str:
        if isinstance(node, ast.Name):
            return self.types.get(node.id, "i32")
        if isinstance(node, ast.Subscript):
            return self.types.get(getattr(node.value, "id", ""), "f32")
        if isinstance(node, ast.Constant):
            return "f32" if isinstance(node.value, float) else "i32"
        if isinstance(node, ast.Call):
            return "i32" if getattr(node.func, "id", "") in ("tid", "bid", "bdim") else "i32"
        if isinstance(node, ast.BinOp):
            a, b = self.expr_type(node.left), self.expr_type(node.right)
            return "f32" if "f32" in (a, b) or "f64" in (a, b) else "i32"
        return "i32"

    def expr(self, node: ast.AST) -> str:
        if isinstance(node, ast.Name):
            return node.id
        if isinstance(node, ast.Constant):
            if isinstance(node.value, bool):
                return "1" if node.value else "0"
            return repr(node.value)
        if isinstance(node, ast.Subscript):
            return "%s[%s]" % (self.expr(node.value), self.expr(node.slice))
        if isinstance(node, ast.UnaryOp):
            op = {ast.UAdd: "+", ast.USub: "-"}.get(type(node.op))
            if op is None:
                raise SyntaxError("toan tu unary khong ho tro: %s" % type(node.op).__name__)
            return "%s(%s)" % (op, self.expr(node.operand))
        if isinstance(node, ast.BinOp):
            op = {
                ast.Add: "+", ast.Sub: "-", ast.Mult: "*", ast.Div: "/",
                ast.FloorDiv: "/", ast.Mod: "%",
            }.get(type(node.op))
            if op is None:
                raise SyntaxError("toan tu khong ho tro: %s" % type(node.op).__name__)
            return "(%s %s %s)" % (self.expr(node.left), op, self.expr(node.right))
        if isinstance(node, ast.Compare):
            parts = [self.expr(node.left)]
            for op, cmp in zip(node.ops, node.comparators):
                sym = {
                    ast.Lt: "<", ast.LtE: "<=", ast.Gt: ">", ast.GtE: ">=",
                    ast.Eq: "==", ast.NotEq: "!=",
                }.get(type(op))
                if sym is None:
                    raise SyntaxError("phep so sanh khong ho tro")
                parts.append("%s %s" % (sym, self.expr(cmp)))
            return " ".join(parts)
        if isinstance(node, ast.BoolOp):
            sym = "&&" if isinstance(node.op, ast.And) else "||"
            return "(%s)" % (" %s " % sym).join(self.expr(v) for v in node.values)
        if isinstance(node, ast.Call):
            name = getattr(node.func, "id", "")
            if name == "tid":
                return "(blockIdx.x * blockDim.x + threadIdx.x)"
            if name == "bid":
                return "blockIdx.x"
            if name == "bdim":
                return "blockDim.x"
            raise SyntaxError("kernel chi goi duoc tid()/bid()/bdim(), khong goi %s()" % name)
        raise SyntaxError("bieu thuc khong ho tro: %s" % type(node).__name__)

    def stmt(self, node: ast.stmt, ind: int):
        pad = "  " * ind
        if isinstance(node, ast.Assign):
            if len(node.targets) != 1:
                raise SyntaxError("chi ho tro 1 target cho moi phep gan")
            t = node.targets[0]
            val = self.expr(node.value)
            if isinstance(t, ast.Name):
                self.types[t.id] = self.expr_type(node.value)
                self.lines.append("%s%s %s = %s;" % (pad, DTYPE_TO_C.get(self.types[t.id], "float"), t.id, val))
            elif isinstance(t, ast.Subscript):
                self.lines.append("%s%s = %s;" % (pad, self.expr(t), val))
            else:
                raise SyntaxError("target gan khong ho tro")
        elif isinstance(node, ast.AugAssign):
            sym = {ast.Add: "+=", ast.Sub: "-=", ast.Mult: "*=", ast.Div: "/="}.get(type(node.op))
            if sym is None:
                raise SyntaxError("AugAssign khong ho tro")
            self.lines.append("%s%s %s %s;" % (pad, self.expr(node.target), sym, self.expr(node.value)))
        elif isinstance(node, ast.If):
            self.lines.append("%sif (%s) {" % (pad, self.expr(node.test)))
            for s in node.body:
                self.stmt(s, ind + 1)
            if node.orelse:
                self.lines.append("%s} else {" % pad)
                for s in node.orelse:
                    self.stmt(s, ind + 1)
            self.lines.append("%s}" % pad)
        elif isinstance(node, ast.Expr) and isinstance(node.value, ast.Call):
            self.lines.append("%s%s;" % (pad, self.expr(node.value)))
        elif isinstance(node, ast.Pass):
            self.lines.append("%s;  /* pass */" % pad)
        else:
            raise SyntaxError("lenh khong ho tro: %s" % type(node).__name__)

    def body(self) -> str:
        for s in self.k.body:
            self.stmt(s, 1)
        return "\n".join(self.lines)

    def c_params(self, with_launch_extra: bool = False) -> str:
        out = []
        for a in self.k.args:
            ann = ann_of(a)
            base = _base_type(ann)
            ctype = DTYPE_TO_C.get(base, "float")
            if _is_ptr(ann):
                const = "const " if a.arg not in self.written else ""
                out.append("%s%s* __restrict__ %s" % (const, ctype, a.arg))
            else:
                out.append("%s %s" % (ctype, a.arg))
        if with_launch_extra:
            out += ["int grid", "int block"]
        return ", ".join(out)


def py_expr_to_c(expr: str) -> str:
    return expr.replace("//", "/").replace("**", "powf")


def gen_cu(kernels: List[Kernel]) -> str:
    chunks = [
        "/* Sin boi tkv_cuda.py (prototype). Dung: nvcc -O2 -shared -fPIC ... */",
        '#include <cuda_runtime.h>',
        '#include <stdint.h>',
        "",
    ]
    for k in kernels:
        g = CGenerator(k)
        chunks.append('extern "C" __global__ void tkv_kernel_%s(%s) {' % (k.name, g.c_params()))
        chunks.append(g.body())
        chunks.append("}")
        chunks.append("")
        chunks.append("extern \"C\" int tkv_launch_%s(%s) {" % (k.name, g.c_params(True)))
        chunks.append("  tkv_kernel_%s<<<grid, block>>>(%s);" % (
            k.name, ", ".join(a.arg for a in k.args)))
        chunks.append("  cudaError_t launch_err = cudaGetLastError();")
        chunks.append("  cudaDeviceSynchronize();   /* host must see kernel writes */")
        chunks.append("  cudaError_t sync_err = cudaGetLastError();")
        chunks.append("  return (int)(launch_err != cudaSuccess ? launch_err : sync_err);")
        chunks.append("}")
        chunks.append("")
    return "\n".join(chunks)


def gen_glue(kernels: List[Kernel], dll: str) -> str:
    entries = []
    funcs = []
    for k in kernels:
        g = CGenerator(k)
        cvtypes = []
        ktypes = []
        for a in k.args:
            ann = ann_of(a)
            base = _base_type(ann)
            ktypes.append('"%s"' % base)
            cvtypes.append('"i64"' if _is_ptr(ann) else '"%s"' % base)
        cvtypes += ['"i32"', '"i32"']
        sym = "tkv_launch_" + k.name
        entries.append(
            '    {"name": "%s", "dll": "%s", "symbol": "%s",\n'
            '     "convention": "cdecl", "params": [%s], "returns": "i32"},'
            % (sym, dll, sym, ", ".join(cvtypes))
        )
        sig = ", ".join(
            '%s: "%s"' % (a.arg, ("i64" if _is_ptr(ann_of(a)) else _base_type(ann_of(a))))
            for a in k.args
        )
        sig += ', grid: "i32", block: "i32"'
        call = "%s(%s, grid, block)" % (sym, ", ".join(a.arg for a in k.args))
        funcs.append(
            "def %s_launch(%s) -> \"i32\":\n    return %s\n" % (k.name, sig, call)
        )
    body = "__tkv_extern_pinvoke__ = [\n" + "\n".join(entries) + "\n]\n\n\n" + "\n\n".join(funcs)
    return body


def strip_kernels(source: str, kernels: List[Kernel]) -> str:
    lines = source.splitlines()
    drop = set()
    for k in kernels:
        drop.update(range(k.line_start, k.line_end))
    return "\n".join(l for i, l in enumerate(lines) if i not in drop)


def merge_pragma(host: str, glue: str) -> str:
    """No cac entry __tkv_extern_pinvoke__ vao file .tkv da co (neu co)."""
    pragma_block, wrappers = glue.split("\n\n\n", 1)
    entries = pragma_block.split("[\n", 1)[1].rsplit("\n]", 1)[0]
    names = re.findall(r'"name": "([^"]+)"', entries)
    if all(('"name": "%s"' % n) in host for n in names):
        return host + "\n\n" + wrappers  # da co pragma, chi them wrapper

    start = re.search(r"__tkv_extern_pinvoke__\s*=\s*\[", host)
    if not start:
        lines = host.splitlines()
        pos = 1 if lines and lines[0].startswith("# -*- coding") else 0
        return "\n".join(lines[:pos]) + "\n" + pragma_block + "\n\n" + "\n".join(lines[pos:]) + "\n\n" + wrappers

    i = start.end()
    depth = 1
    while i < len(host) and depth:
        if host[i] == "[":
            depth += 1
        elif host[i] == "]":
            depth -= 1
        i += 1
    close = i - 1
    before = host[:close].rstrip()
    sep = ",\n" if before and not before.endswith(",") else "\n"
    return before + sep + entries + host[close:] + "\n\n" + wrappers


def gen_build(kernel_names: List[str], out_so: str) -> str:
    return (
        "#!/bin/sh\n"
        "# Sin boi tkv_cuda.py -- chay trong Colab (can nvcc). \n"
        "set -e\n"
        "TKV_DIR=/content/TokenVector/Release/tools/simd_native\n"
        "nvcc -O2 -shared -std=c++20 --expt-relaxed-constexpr -x cu \\\n"
        "  -Xcompiler -std=c++20 -Xcompiler -fPIC \\\n"
        "  $TKV_DIR/tkv_cuda_kernels.cu -o %s \\\n"
        "  -lcudart\n"
        "echo 'built %s'\n" % (out_so, out_so)
    )


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="Prototype CUDA backend cho TokenVector")
    ap.add_argument("input", help="file .tkv co kernel # @tkv.cuda_kernel")
    ap.add_argument("command", nargs="?", default="gen", choices=["gen", "check"])
    ap.add_argument("-o", "--outdir", default=".", help="thu muc output")
    ap.add_argument("--dll", default="tkv_cuda_kernels", help="ten .so se load luc chay")
    args = ap.parse_args(argv)

    source = open(args.input, encoding="utf-8").read()
    kernels = parse_kernels(source)
    if not kernels:
        print("Khong tim thay kernel nao (can '# @tkv.cuda_kernel grid=\"...\" block=...')")
        return 1
    for k in kernels:
        CGenerator(k).body()  # validate sớm, bao loi truoc khi ghi file
    print("OK: %d kernel: %s" % (len(kernels), ", ".join(k.name for k in kernels)))
    if args.command == "check":
        return 0

    os.makedirs(args.outdir, exist_ok=True)
    stem = os.path.splitext(os.path.basename(args.input))[0]
    cu = os.path.join(args.outdir, stem + ".cuda.cu")
    glue = os.path.join(args.outdir, stem + ".cuda.tkv")
    sh = os.path.join(args.outdir, stem + ".cuda.build.sh")
    merged = os.path.join(args.outdir, stem + ".with_cuda.tkv")

    open(cu, "w", encoding="utf-8", newline="\n").write(gen_cu(kernels))
    gtext = gen_glue(kernels, args.dll)
    open(glue, "w", encoding="utf-8", newline="\n").write(gtext)
    open(sh, "w", encoding="utf-8", newline="\n").write(gen_build([k.name for k in kernels], args.dll + ".so"))
    host = strip_kernels(source, kernels)
    open(merged, "w", encoding="utf-8", newline="\n").write(merge_pragma(host, gtext))
    print("Da sinh:")
    for p in (cu, glue, sh, merged):
        print("  " + p)
    return 0


if __name__ == "__main__":
    sys.exit(main())
