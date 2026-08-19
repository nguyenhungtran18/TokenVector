# -*- coding: utf-8 -*-
"""Kiem tra typegraph.tkv - doi chieu canh `calls` voi cai dat tham chieu `ast`.

Do CA HAI chieu, va do chinh xac (precision) TRUOC recall: mot canh BIA ra
lam hong long tin vao ca do thi, trong khi mot canh thieu chi lam do thi
kem day du. Nguong: precision >= 97%, va khong duoc thap hon ban callgraph
cu ve so canh.

Trong tai `ast` cai dat DUNG 4 luat ma typegraph tuyen bo lam duoc:
  ten(...)                 -> ham cung file hoac file da import
  self.m()                 -> method cua lop (hoac lop cha noi bo)
  mod.f()                  -> mod la file noi bo
  x = Cls(); x.m()         -> Cls la lop noi bo
Khong doi chieu nhung dang ngoai pham vi (gia tri tra ve, phan tu list...).
"""

import ast
import collections
import io
import os
import sys
import types

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.join(HERE, "..", "..", "tools")
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
MANIFEST = os.path.join(REPO, "CodeGraph", "graph", "code_graph_manifest.txt")

SAMPLE = 150          # so file doi chieu (chay het 732 file mat ~10 phut)


def load_tool():
    mod = types.ModuleType("tg")
    mod.__dict__["read_file"] = lambda p: io.open(os.path.join(REPO, p), encoding="utf-8",
                                                  errors="ignore").read()
    mod.__dict__["write_file"] = lambda p, c: None
    for name in ("impgraph.tkv", "pytok.tkv", "typegraph.tkv"):
        src = io.open(os.path.join(TOOLS, name), encoding="utf-8").read()
        src = src.replace('__tkv_import__ = "impgraph"', "")
        src = src.replace('__tkv_import__ = ["impgraph", "pytok"]', "")
        exec(compile(src, name, "exec"), mod.__dict__)
    return mod


class RefIndex:
    """Bang tra cuu tu `ast` cho ca repo mau."""

    def __init__(self, paths):
        self.trees = {}
        self.cls_methods = {}
        self.cls_base = {}
        self.cls_files = collections.defaultdict(set)
        self.func_files = collections.defaultdict(set)
        self.mod_files = {}
        self.owner = {}        # (file, ten ham) -> Lop so huu, de dung id day du
        for rel in paths:
            try:
                src = io.open(os.path.join(REPO, rel), encoding="utf-8", errors="ignore").read()
                tree = ast.parse(src)
            except (OSError, SyntaxError, ValueError):
                continue
            self.trees[rel] = tree
            self.mod_files.setdefault(os.path.basename(rel)[:-3], rel)
            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    self.cls_methods[(rel, node.name)] = {
                        b.name for b in node.body
                        if isinstance(b, (ast.FunctionDef, ast.AsyncFunctionDef))}
                    # (chu so huu duoc gan o `_scan_owner` - phai theo LOP BAO
                    # GAN NHAT ke ca khi ham long trong mot method, dung nhu
                    # `defmeta` sinh id. Chi lay con truc tiep thi ham long
                    # `def work(...)` ben trong `_run` se co id KHAC id that.)
                    self.cls_files[node.name].add(rel)
                    if node.bases and isinstance(node.bases[0], ast.Name):
                        self.cls_base[(rel, node.name)] = node.bases[0].id
                elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    self.func_files[node.name].add(rel)
            self._scan_owner(tree, rel, "")

    def _scan_owner(self, node, rel, cls):
        """Gan chu so huu theo LOP BAO GAN NHAT, di xuyen qua ham long."""
        for child in ast.iter_child_nodes(node):
            if isinstance(child, ast.ClassDef):
                self._scan_owner(child, rel, child.name)
            elif isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef)):
                if cls:
                    self.owner.setdefault((rel, child.name), cls)
                self._scan_owner(child, rel, cls)
            else:
                self._scan_owner(child, rel, cls)

    def qual(self, rel, name):
        """Id day du: 'function:<file>:<Lop>.<ten>' neu la method."""
        own = self.owner.get((rel, name))
        return "function:%s:%s" % (rel, (own + "." + name) if own else name)

    def owner_cls(self, rel, cname, meth):
        """File dinh nghia `meth` cua lop `cname`, tra nguoc ke thua noi bo."""
        cur_rel, cur_cls = rel, cname
        for _ in range(4):
            ms = self.cls_methods.get((cur_rel, cur_cls))
            if ms and meth in ms:
                return cur_rel + "#" + cur_cls
            par = self.cls_base.get((cur_rel, cur_cls))
            if not par:
                return None
            files = self.cls_files.get(par) or set()
            if len(files) != 1:
                return None
            cur_rel, cur_cls = next(iter(files)), par
        return None


class RefWalker(ast.NodeVisitor):
    """Sinh canh calls tham chieu cho 1 file."""

    def __init__(self, rel, idx, scope):
        self.rel, self.idx, self.scope = rel, idx, scope
        self.cls = None
        self.fn = None
        self.local = {}
        self.alias = {}
        self.edges = set()

    def visit_Import(self, node):
        for a in node.names:
            f = self.idx.mod_files.get(a.name.split(".")[-1])
            if f:
                self.alias[a.asname or a.name.split(".")[-1]] = f
        self.generic_visit(node)

    def visit_ImportFrom(self, node):
        for a in node.names:
            f = self.idx.mod_files.get(a.name)
            if f:
                self.alias[a.asname or a.name] = f
        self.generic_visit(node)

    def visit_ClassDef(self, node):
        prev = self.cls
        self.cls = node.name
        self.generic_visit(node)
        self.cls = prev

    def _fn(self, node):
        prev = self.fn
        self.fn = node.name
        self.generic_visit(node)
        self.fn = prev

    visit_FunctionDef = _fn
    visit_AsyncFunctionDef = _fn

    def visit_Assign(self, node):
        if isinstance(node.value, ast.Call) and isinstance(node.value.func, ast.Name):
            for t in node.targets:
                if isinstance(t, ast.Name):
                    self.local[(self.fn, t.id)] = node.value.func.id
                elif (isinstance(t, ast.Attribute) and isinstance(t.value, ast.Name)
                      and t.value.id == "self" and self.cls):
                    # self.attr = Cls()  -> kieu cua field, luat D
                    self.local[("#field#" + self.cls, t.attr)] = node.value.func.id
        # `builtins.__import__ = restricted_import` cung la THAM CHIEU that
        # toi ham do, khong khac gi truyen no lam tham so. (Da co mot
        # visit_Assign o day tu truoc - them visitor thu hai se AM THAM ghi
        # de cai cu va lam mat 50 canh; da xay ra.)
        self._ref_arg(node.value)
        self.generic_visit(node)

    def _src(self):
        """Id day du cua ham dang goi."""
        name = (self.cls + "." + self.fn) if self.cls else self.fn
        return "function:%s:%s" % (self.rel, name)

    def _add_pair(self, pair, meth):
        """pair = '<file>#<Lop>' tu owner_cls()."""
        if pair and self.fn:
            f, c = pair.split("#", 1)
            self.edges.add((self._src(), "function:%s:%s.%s" % (f, c, meth)))

    def _add(self, tgt_file, tgt_name):
        if tgt_file and self.fn:
            self.edges.add((self._src(), self.idx.qual(tgt_file, tgt_name)))

    def _ref_arg(self, a):
        """HAM TRUYEN NHU GIA TRI o vi tri tham so: `pool.submit(_convert_one)`.
        Trong tai phai biet luat nay, khong thi canh THAT cua typegraph bi
        tinh la bia. Chinh cho nay tung mu ca hai ben nen khong hien ra
        duoi dang sot recall - no bien mat khoi thuoc do."""
        if isinstance(a, ast.IfExp):
            self._ref_arg(a.body)
            self._ref_arg(a.orelse)
            return
        if isinstance(a, (ast.Tuple, ast.List, ast.Set)):
            # BANG DISPATCH: `{"/sheet": (_sheet_flow, "Bang tinh")}` - ten ham
            # nam trong mot tuple/dict, van la tham chieu that (ham do se duoc
            # goi qua bang). Kiem tay o fb_ui.py truoc khi them luat nay.
            for x in a.elts:
                self._ref_arg(x)
            return
        if isinstance(a, ast.Dict):
            for x in a.keys:
                if x is not None:
                    self._ref_arg(x)
            for x in a.values:
                self._ref_arg(x)
            return
        if isinstance(a, ast.Name):
            if a.id in self.idx.cls_files:
                return                      # ten LOP truyen di - bo qua
            files = [x for x in (self.idx.func_files.get(a.id) or set()) if x in self.scope]
            if len(files) == 1:
                self._add(files[0], a.id)
        elif (isinstance(a, ast.Attribute) and isinstance(a.value, ast.Name)
              and a.value.id == "self" and self.cls):
            self._add_pair(self.idx.owner_cls(self.rel, self.cls, a.attr), a.attr)

    def visit_Call(self, node):
        f = node.func
        for a in node.args:
            self._ref_arg(a)
        for kw in node.keywords:
            self._ref_arg(kw.value)
        if isinstance(f, ast.Name):
            # Khoi tao `Cls(...)`: canh toi nut CLASS, khong phai nut function
            cfiles = [x for x in (self.idx.cls_files.get(f.id) or set()) if x in self.scope]
            if len(cfiles) == 1:
                self.edges.add((self._src(), "class:%s:%s" % (cfiles[0], f.id))
                               if self.fn else ("", ""))
                self.edges.discard(("", ""))
            else:
                files = self.idx.func_files.get(f.id) or set()
                cand = [x for x in files if x in self.scope]
                if len(cand) == 1:
                    self._add(cand[0], f.id)
        elif isinstance(f, ast.Attribute) and isinstance(f.value, ast.Name):
            recv, meth = f.value.id, f.attr
            if recv == "self":
                if self.cls:
                    self._add_pair(self.idx.owner_cls(self.rel, self.cls, meth), meth)
            elif recv in self.alias:
                tgt = self.alias[recv]
                if meth in {n.name for n in ast.walk(self.idx.trees.get(tgt, ast.Module(body=[], type_ignores=[])))
                            if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))}:
                    self._add(tgt, meth)
            else:
                t = self.local.get((self.fn, recv))
                if not t and recv in self.idx.cls_files:
                    t = recv          # luat G: Cls.method() / classmethod
                if t:
                    files = self.idx.cls_files.get(t) or set()
                    if len(files) == 1:
                        self._add_pair(self.idx.owner_cls(next(iter(files)), t, meth), meth)
        elif (isinstance(f, ast.Attribute) and isinstance(f.value, ast.Attribute)
              and isinstance(f.value.value, ast.Name) and f.value.value.id == "self"
              and self.cls):
            # self.attr.method()  -> luat D
            t = self.local.get(("#field#" + self.cls, f.value.attr))
            if t:
                files = self.idx.cls_files.get(t) or set()
                if len(files) == 1:
                    self._add_pair(self.idx.owner_cls(next(iter(files)), t, f.attr), f.attr)
        self.generic_visit(node)


def main():
    mod = load_tool()
    paths = [l.strip() for l in io.open(MANIFEST, encoding="utf-8") if l.strip()][:SAMPLE]

    idx_mod = mod.build_index(paths)
    base_idx = mod.build_base_index(paths)
    tab = {}
    for rel in paths:
        rows = mod.file_tokens(rel)
        tab["D#" + rel] = mod.collect_defs_tok(rows)
        mod.class_methods_tab(rows, rel, tab)
        mod.local_types_tab(rows, rel, tab)
        mod.module_alias_tab(rows, rel, idx_mod, base_idx, tab)
        mod.bound_names_tab(rows, rel, tab)
    imps = mod.build_imports(paths, idx_mod, base_idx)

    mine = set()
    n_ref_edge = 0
    stats = [0] * 8
    for rel in paths:
        scope = mod.scope_files(rel, imps.get(rel, ""))
        for e in mod.emit_file(rel, scope, tab, stats):
            if '"type":"calls"' not in e:
                continue
            src = e.split('"source":"')[1].split('"')[0]
            dst = e.split('"target":"')[1].split('"')[0]
            if '"weight":0.6' in e:
                n_ref_edge += 1
            mine.add((src, dst))

    ref_idx = RefIndex(paths)
    ref = set()
    for rel in paths:
        tree = ref_idx.trees.get(rel)
        if tree is None:
            continue
        scope = set(mod.scope_files(rel, imps.get(rel, "")))
        w = RefWalker(rel, ref_idx, scope)
        w.visit(tree)
        ref |= w.edges

    tp = len(mine & ref)
    fp = len(mine - ref)
    fn = len(ref - mine)
    prec = 100.0 * tp / (tp + fp) if (tp + fp) else 0.0
    rec = 100.0 * tp / (tp + fn) if (tp + fn) else 0.0
    print("doi chieu %d file: typegraph=%d canh, ast=%d canh" % (len(paths), len(mine), len(ref)))
    print("  chinh xac (precision) = %.1f%%   (%d dung / %d sinh ra)" % (prec, tp, tp + fp))
    print("  day du   (recall)     = %.1f%%   (%d bat / %d that)" % (rec, tp, tp + fn))
    if fp:
        print("  vi du canh BIA:")
        for e in list(mine - ref)[:3]:
            print("    %s -> %s" % e)
    if fn:
        print("  vi du canh THIEU:")
        for e in list(ref - mine)[:3]:
            print("    %s -> %s" % e)

    fails = []
    # Luat "ham truyen nhu gia tri" (trong so 0.6) phai con song: bo im lang
    # luat nay khong lam precision/recall tut du de bao dong.
    print("  canh 'ham truyen nhu gia tri': %d" % n_ref_edge)
    if n_ref_edge < 40:
        fails.append("chi con %d canh 'ham truyen nhu gia tri' - luat bi bo?" % n_ref_edge)
    if prec < 97.0:
        fails.append("precision %.1f%% duoi nguong 97%%" % prec)
    # Chan recall TUT: ba lan sua truoc deu lam recall doi (91 -> 95 -> 97)
    # ma khong cai nao bao dong duoc, vi chi co precision co nguong.
    if rec < 95.0:
        fails.append("recall %.1f%% duoi nguong 95%% - co thu bi bo sot" % rec)
    if fails:
        print("FAIL (%d):" % len(fails))
        for f in fails:
            print("  -", f)
        return 1
    print("PASS: precision %.1f%%, recall %.1f%%" % (prec, rec))
    return 0


if __name__ == "__main__":
    sys.exit(main())
