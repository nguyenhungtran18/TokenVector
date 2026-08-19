# -*- coding: utf-8 -*-
"""AlphaAI: core sinh code DSL bang AI (Groq qua AI Connect) cho TokenVector.

Pham vi THAT (khong phong dai): TokenVector CLI (tokenvector_compile.py)
chi bien dich DUNG 1 khuon mau co san (1 hidden layer, dense/normalize/
argmax). AlphaAI lap khoang trong do: khi nguoi dung mo ta mot kien truc
KHONG khop khuon mau (vd 2 hidden layer, mix nhieu activation, logic
dieu kien rieng), AlphaAI (LLM) TU VIET than ham DSL, va than ham do
DUOC BIEN DICH THAT qua il_codegen.gen_il_function + ilasm.exe de xac
nhan dung cu phap - khong bao gio bao "co ve dung" ma khong bien dich
that. Neu nguoi dung dua san trong so + 1 phep tinh tham chieu doc lap
(numpy), ket qua .exe con duoc doi chieu SO HOC (khong chi cu phap).
"""
import re
import sys
from pathlib import Path

COMPILER_DIR = Path(__file__).parent / "compiler"
sys.path.insert(0, str(COMPILER_DIR))
sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, r"C:\Claude AI Project")

from typed_dsl_parser import parse_typed_signature  # noqa: E402
from il_codegen import gen_il_function  # noqa: E402
from ai_connect import AIConnectOrchestrator  # noqa: E402

_DSL_REFERENCE = '''Ban dang viet THAN HAM (khong viet dong chu ky) cho mot
ngon ngu DSL nho (TokenVector) bien dich thang ra CIL.
Cu phap HOP LE (chi duoc dung dung cac dang sau, KHONG duoc bia them):

- Gan bien vo huong:      ten = bieu_thuc
- Tao mang 1 chieu:       ten = np.zeros(N, dtype=np.float32)
- Gan phan tu mang:       ten[i] = bieu_thuc
- Vong lap for range:     for i in range(N):
                              <than vong lap, thut le 4 dau cach>
- Vong lap qua list:      for x in lst:
- Vong lap qua dict:      for k, v in d.items():
- break / continue        (hop le trong for/while, KHONG hop le trong finally:)
- Vong lap while:         while dieu_kien:
- Re nhanh:               if bieu_thuc:
                              <than>
                          else:
                              <than>
- Tra ve 1 gia tri:       return bieu_thuc
- Tra ve 2 gia tri:       return bieu_thuc1, bieu_thuc2   (chi khi chu ky co
                          return type dang "(dtype, dtype)")
- Giai nen/gan song song: x, y = f(...)   hoac   x, y = a, b   (ke ca hoan doi)
- Bieu thuc: so, ten bien, ten[i], ten[i, j], chuoi "..." trong dau ngoac
  kep, + - * / % (cong chuoi CHI dung '+', KHONG dung % cho string), so
  sanh (> < >= <= == !=), and/or, "not bieu_thuc" (phu dinh boolean),
  ba-ngoi KIEU C (KHONG phai kieu Python): "cond ? gia_tri_dung : gia_tri_sai"
  (vi du "x >= lo and x <= hi ? x : lo" - TUYET DOI KHONG duoc viet
  "x if cond else lo" kieu Python, DSL nay KHONG ho tro cu phap do), ham
  toan hoc exp/sqrt/tanh/sin/cos, dau am unary, "key in d" (kiem tra khoa
  co trong dict).
- Gan rut gon:            ten += bieu_thuc   (cung vay voi -= *= /= %=;
                          dung duoc tren bien thuong, "obj.field += x",
                          va "lst[i] += x")
- Tu nem loi:             raise <Loai>("thong diep")   (Loai: Exception,
                          ZeroDivisionError, KeyError, IndexError,
                          ValueError, OverflowError - GIONG loai dung
                          duoc trong "except <Loai>:")
- List DONG:     lst = []                       # tao list rong
                 lst.append(gia_tri)             # them phan tu
                 lst[i]                          # doc theo chi so
                 len(lst)                        # so phan tu
- Dict DONG:     d = {}                          # tao dict rong
                 d[key] = gia_tri                # ghi
                 d[key]                          # doc
                 key in d                        # kiem tra ton tai
                 len(d)                          # so phan tu
- String:        s[i]                            # 1 ky tu (van la string do dai 1)
                 len(s)                          # do dai
                 s1 + s2                          # noi chuoi
                 str(so)                          # doi so -> chuoi
- File I/O:      read_file(path)                  # -> str (bieu thuc)
                 file_exists(path)                # -> i32 0/1 (bieu thuc)
                 write_file(path, content)        # LENH DOC LAP (khong gan bien)
                 append_file(path, content)       # LENH DOC LAP (khong gan bien)
- try/except/finally:
      try:
          <than>
      except <Ten loai loi hoac de trong>:        # vd 'except ZeroDivisionError:'
          <than>                                  # loai ho tro: Exception,
      finally:                                     # ZeroDivisionError, KeyError,
          <than>                                   # IndexError, ValueError, OverflowError
- MACRO co san CHO MANG CO DINH (chi dung khi dung ngu nghia):
    ten = normalize(x, x_min, x_max)         # (x-min)/(max-min) tung phan tu
    ten = dense(x, w, b, 'tanh')             # 'tanh'|'sigmoid'|'relu'|'none'
    ten = argmax(x)                          # tra ve CHI SO (float) phan tu lon nhat
    ten = add(a, b) / sub(a, b) / mul(a, b)  # cong/tru/nhan tung phan tu, cung shape
    ten = scale(x, k)                        # nhan vo huong
    ten = matvec(w, x)                       # ma tran x vector
    ten = apply(x, 'tanh')                   # ap ham len tung phan tu

KHONG duoc dung cu phap Python khac (list/dict comprehension, class, def,
import, lambda, generator/yield, decorator, raise tuy y). Class dang record
(field-only) va tham so/return kieu record CHUA duoc AlphaAI nay ho tro
sinh (can ctx rieng, xem STATUS.md) - KHONG viet code dung "obj.field" hay
goi "TenClass(...)" nhu constructor.
CHI tra ve than ham (khong co dong chu ky 'ten(...) -> ...:' o dau), moi
dong 1 lenh, dat trong 1 khoi ma ```dsl ... ``` duy nhat.

QUAN TRONG: MOI macro mang co dinh (normalize/dense/argmax/add/sub/mul/
scale/matvec/apply) CHI duoc dung o dang GAN TRUC TIEP cho 1 bien:
"ten = macro(...)". TUYET DOI KHONG duoc goi macro long trong bieu thuc
khac hay truc tiep trong "return" (vi du "return argmax(o)" LA SAI cu
phap - phai viet "best_idx = argmax(o)" roi dong ke tiep "return best_idx").'''


def _extract_code_block(text):
    m = re.search(r'```(?:dsl)?\s*\n(.*?)```', text, re.DOTALL)
    return (m.group(1) if m else text).strip('\n')


def generate_dsl_body(task_description, signature_line, provider='groq', max_tokens=1200):
    """Goi LLM sinh than ham DSL cho `signature_line` theo mo ta
    `task_description`. Tra ve (raw_llm_text, body_lines)."""
    orchestrator = AIConnectOrchestrator()
    prompt = (
        f"{_DSL_REFERENCE}\n\n"
        f"Chu ky ham (KHONG lap lai dong nay trong cau tra loi, chi viet than ham):\n"
        f"  {signature_line}\n\n"
        f"Yeu cau: {task_description}\n\n"
        f"Viet than ham DSL thuc hien dung yeu cau tren, dat trong 1 khoi ```dsl ``` duy nhat."
    )
    resp = orchestrator.call(provider, prompt, max_tokens=max_tokens, temperature=0.2)
    if not resp.is_success():
        return resp.content, None, f"AI Connect loi: {resp.error}"
    code = _extract_code_block(resp.content)
    body_lines = [l for l in code.split('\n') if l.strip()]
    return resp.content, body_lines, None


def compile_generated(signature_line, body_lines):
    """Bien dich THAT (khong doan mo) than ham do AI sinh ra qua
    il_codegen.gen_il_function. Tra ve (il_method_lines, error_message)."""
    try:
        sig = parse_typed_signature(signature_line)
        il_lines = gen_il_function(sig, body_lines)
        return il_lines, None
    except Exception as e:  # noqa: BLE001 - can bao loi THAT tu bo dich, khong duoc nuot
        return None, f"{type(e).__name__}: {e}"


def generate_and_verify(task_description, signature_line, provider='groq', max_attempts=3):
    """Pipeline day du: sinh code -> bien dich THAT -> neu loi, gui LOI
    THAT nguoc lai cho AI de tu sua (khong phai minh sua ho) -> thu lai
    toi da `max_attempts` lan. Tra ve ket qua trung thuc, bao gom ca
    lich su cac lan thu that bai (khong che giau)."""
    attempts = []
    desc = task_description
    for attempt_no in range(1, max_attempts + 1):
        raw, body_lines, err = generate_dsl_body(desc, signature_line, provider)
        if err:
            attempts.append({'attempt': attempt_no, 'raw_llm_output': raw, 'error': err})
            return {'success': False, 'stage': 'llm_call', 'raw_llm_output': raw,
                    'body_lines': None, 'il_lines': None, 'error': err, 'attempts': attempts}
        il_lines, compile_err = compile_generated(signature_line, body_lines)
        attempts.append({'attempt': attempt_no, 'raw_llm_output': raw,
                          'body_lines': body_lines, 'error': compile_err})
        if not compile_err:
            return {'success': True, 'stage': 'done', 'raw_llm_output': raw,
                    'body_lines': body_lines, 'il_lines': il_lines, 'error': None,
                    'attempts': attempts}
        desc = (f"{task_description}\n\nLAN TRUOC BAN VIET:\n{chr(10).join(body_lines)}\n\n"
                f"NHUNG BIEN DICH THAT BAI VOI LOI: {compile_err}\n"
                f"Hay sua lai cho DUNG cu phap DSL da mo ta, giu nguyen y do ban dau.")
    return {'success': False, 'stage': 'compile', 'raw_llm_output': attempts[-1]['raw_llm_output'],
            'body_lines': attempts[-1]['body_lines'], 'il_lines': None,
            'error': attempts[-1]['error'], 'attempts': attempts}
