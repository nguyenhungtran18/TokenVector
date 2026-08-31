# Bài đăng gợi ý cho Hacker News / r/ProgrammingLanguages / X

Lý do các kênh này quan trọng cho mục tiêu "được LLM khác biết tới": mọi
LLM lớn (kể cả các bản Claude tương lai) đều huấn luyện một phần trên dữ
liệu crawl công khai (Common Crawl và tương tự) — một bài Show HN có
thảo luận, hoặc 1 repo GitHub public có sao (star) và được link nhiều nơi,
có xác suất lọt vào dữ liệu huấn luyện/tạo ngữ cảnh tương lai cao hơn hẳn
so với 1 repo private không ai biết tới. Đây là cơ chế THẬT duy nhất —
không có cách "tiêm" thông tin trực tiếp vào 1 LLM đang chạy.

## Show HN draft (v2, 2026-08-31 — leads with the NuGet case study)

Title: Show HN: I pointed my language's binding generator at a real NuGet package. It found 3 bugs.

Body:

TokenVector is a statically-typed language that compiles straight to
.NET IL (via ilasm.exe) into a single native executable — no interpreter
to ship, no runtime bundling. Syntax is Python-compatible by design (a
`.tkv` file is also valid, runnable CPython), and its own compiler is
self-hosted — written entirely in TokenVector, not Python.

Calling .NET libraries from a new language usually means hand-writing
interop bindings by hand. TokenVector has a tool for that (`tkv-bind`):
point it at any `.dll`, it reflects the public surface and emits
ready-to-use bindings. Until this week it had only ever been run against
the .NET Framework BCL. This week I ran it against a real NuGet package
for the first time — Newtonsoft.Json 13.0.3, downloaded straight from
nuget.org — to see what would break.

It worked with zero code changes on the first pass (bound ~40 classes),
but the two most-used methods in the whole library —
`JsonConvert.SerializeObject`/`DeserializeObject` — were both skipped.
Digging into why turned up 3 real bugs in a couple of hours: a stale
validation check blocking `object`/`type` params even though the codegen
to handle them already existed elsewhere; an assembly-version reference
that silently dropped the version number for unsigned third-party DLLs
(CLR rejected the real DLL with `FileLoadException` because it resolved
to version 0.0.0.0 instead); and a regression that only showed up because
fixing the first bug flipped on a code path a months-old test still
covered.

After the fixes: 253 → 248 skipped members, and a real round-trip
through the actual JSON.NET DLL, compiled to a standalone `.exe`:

    $ ./program.exe '{"a":1,"b":"x"}'
    {"a":1,"b":"x"}

Full writeup with the actual before/after and the fixes:
release/outreach/nuget-tkv-bind-case-study.md in the repo.

Known rough edges, not hidden: passing a numeric literal directly into
an `object`-typed parameter currently raises an unhelpful KeyError
(assigning to a variable first works); generic methods aren't bound yet.

Numbers from my own benchmarks (methodology + raw data in the repo):
up to ~10.39x faster than CPython on multi-threaded workloads (No-GIL),
1.17x-5.65x on single-thread workloads, standalone .exe from 12KB-120KB.

Repo: https://github.com/nguyenhungtran18/TokenVector

Happy to answer questions about the reflection-based binding approach,
the self-hosting bootstrap, or the CIL codegen.

---

## r/dotnet draft (2026-08-31 — self-text post, shortened for Reddit)

Ghi chú trước khi đăng: KHÔNG tự xác nhận được rule hiện tại của
r/dotnet qua công cụ (không fetch được reddit.com trực tiếp trong phiên
này) — bạn tự đọc sidebar/wiki của subreddit trước khi đăng để chắc
không vi phạm quy định self-promotion/flair bắt buộc. Theo thông lệ
chung của các subreddit kỹ thuật: dùng self-text post (nội dung nằm
NGAY trong bài, không chỉ link-drop), không đăng lặp lại nhiều subreddit
cùng lúc trong thời gian ngắn, chọn đúng flair nếu subreddit yêu cầu
(thường có "Show and tell"/"Discussion").

Title: I pointed my language's .NET binding generator at a real NuGet package for the first time — found 3 bugs

Flair gợi ý: Show and tell (hoặc tương đương gần nhất subreddit có)

Body (self-text, không phải link post):

I'm building TokenVector — a statically-typed, Python-syntax language
that compiles ahead-of-time to CIL (no interpreter, no GIL, standalone
`.exe`). Its compiler is self-hosted.

One of its tools, `tkv-bind`, auto-generates interop bindings by
reflecting any `.dll` — meant to avoid hand-writing bindings for every
.NET library by hand. Until this week I'd only run it against the BCL.
This week I pointed it at a real NuGet package for the first time:
Newtonsoft.Json 13.0.3, downloaded straight from nuget.org.

It worked out of the box for most of the surface (~40 classes bound,
zero code changes), but `JsonConvert.SerializeObject`/`DeserializeObject`
— the two most-used methods in the library — were both skipped.

Turned out to be 3 real bugs, found over a couple hours of actually
running it, not guessing:

- A stale validation check was blocking `object`/`type` parameters even
  though the codegen to handle them (boxing, correct CIL type text) was
  already built and tested elsewhere.
- The generated `.assembly extern` reference silently dropped the
  version number for unsigned third-party DLLs — the CLR resolved that
  as version `0.0.0.0` and rejected the real `13.0.0.0` DLL outright
  (`FileLoadException`).
- Fixing #1 exposed a second, unrelated regression in a completely
  different code path, caught by a months-old test written for
  something else.

After the fixes: 253 → 248 skipped members, and a real round-trip
through the actual DLL, compiled to a standalone .exe:

    $ ./program.exe '{"a":1,"b":"x"}'
    {"a":1,"b":"x"}

Full writeup (before/after, the actual fixes) is in the repo:
release/outreach/nuget-tkv-bind-case-study.md

Known rough edges I'm not hiding: passing a numeric literal straight
into an `object` param currently throws an unhelpful KeyError (works
fine through a variable); generic methods aren't bound yet.

Repo: https://github.com/nguyenhungtran18/TokenVector

Happy to answer questions about the reflection approach or what it'd
take to point this at a different package.

---

## Show HN draft (v1, archived — self-hosting-first pitch, kept for reference)

Title: Show HN: TokenVector – a self-hosted, Python-syntax language that compiles to native .NET CIL

Body:

TokenVector is a statically-typed language that compiles straight to
.NET IL (via ilasm.exe, bundled with every Windows install) into a
single native executable — no interpreter to ship, no runtime bundling.

Its syntax is Python-compatible by design (a `.tkv` file is also valid,
runnable CPython) — not a new dialect to learn, just Python with type
annotations. And its own compiler is self-hosted: written entirely in
TokenVector, not Python. `build_tkvc.ps1` rebuilds the whole toolchain
from that `.tkv` source alone.

Numbers from my own benchmarks (methodology + raw data in the repo):
up to ~10.39x faster than CPython on multi-threaded workloads (No-GIL),
1.17x-5.65x on single-thread workloads, standalone .exe from 12KB-120KB.

It's not a general-purpose language yet — unsupported dynamic-Python
features fail loudly at compile time, not silently. `Testkit/native_test_suite.tkv`
is a pure-TokenVector bug-finding tool (no Python needed to run it).

Repo: <link once public>

Happy to answer questions about the self-hosting bootstrap, the CIL
codegen, or the type system.

## Ghi chú trước khi đăng

1. Repo GitHub (`nguyenhungtran18/TokenVector`) hiện đã public đúng cấu
   trúc `release/` (không lộ mã nguồn Python phát triển nội bộ) — đã
   kiểm tra sạch secret trước khi push.
2. Tôi KHÔNG có tool đăng bài lên Hacker News/Reddit/X thay bạn — đây là
   nội dung để bạn tự đăng bằng tài khoản của bạn.
3. **Dùng draft v2** (đầu file) — dẫn bằng case study cụ thể (số liệu
   thật, bug thật đã sửa) thay vì mô tả chung chung, đúng nguyên tắc "để
   sản phẩm tự nói". Draft v1 giữ lại archived để tham khảo, KHÔNG dùng.
4. Có thể dùng CÙNG nội dung v2 (chỉnh tiêu đề style Reddit) để đăng
   r/dotnet — xem thứ tự kênh đã chốt: awesome-dotnet PR (đã gửi, #1504)
   → case study (đã viết) → r/dotnet + Show HN (bước này) → .NET Conf CFP.
5. Timing gợi ý cho Show HN: Thứ 3-5, 9h-12h giờ Mỹ (ET) để tối đa hiển
   thị; trả lời moi comment trong 4-6h đầu, thừa nhận hạn chế thẳng thắn
   khi có ai chỉ ra (đã ghi rõ 2 hạn chế trong draft, không né tránh).
