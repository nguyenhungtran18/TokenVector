# -*- coding: utf-8 -*-
"""Ho tro CHAY THAT duoi CPython cho cac ham file I/O ma TokenVector coi
la builtin (read_file/write_file/append_file/file_exists). KHONG dinh
nghia truc tiep trong file .tkv: extract_program() co gang transpile MOI
ham top-level no gap trong 1 file .tkv, va than ham nay (mo file that,
goi method .read()/.write()) khong nam trong cu phap DSL da ho tro - se
bao loi ngay. Import module RIENG nay (ast.ImportFrom duoc extract_program
bo qua hoan toan, khong co gang transpile) de file .tkv van la Python
THAT chay duoc ma khong bi hieu nham la than ham can bien dich."""
import os


def read_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()


def write_file(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)


def append_file(path, content):
    with open(path, 'a', encoding='utf-8') as f:
        f.write(content)


def file_exists(path):
    return os.path.exists(path)
