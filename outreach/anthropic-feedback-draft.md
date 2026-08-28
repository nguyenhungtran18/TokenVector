# Nội dung gợi ý gửi Anthropic (feedback trong Claude/Claude Code)

Kênh gửi thật (tôi không có quyền tự gửi thay bạn):
- Trong Claude.ai / Claude Code: lệnh `/bug` hoặc form feedback trong Settings
- support.anthropic.com (form liên hệ chính thức)
- Nếu có tài khoản Anthropic Developer/API: feedback qua console.anthropic.com

Copy đoạn dưới đây (tiếng Anh, ngắn gọn, đúng khuôn "feedback" chứ không
phải "yêu cầu hỗ trợ kỹ thuật" — để tăng khả năng được đọc):

---

Subject: A self-hosted, Python-syntax native language designed for AI-generated code (TokenVector)

I've built TokenVector, an open-source statically-typed language that
compiles directly to .NET CIL (single native .exe, no runtime install,
up to ~10x faster than CPython on multi-threaded workloads). Its syntax
is Python-compatible by design, and its own compiler is self-hosted —
written entirely in TokenVector itself, not Python — so `.tkv` source is
both the implementation language and the target language.

I built this specifically because AI coding agents (including Claude)
are very good at Python-like syntax, but Python's runtime story
(interpreter installs, PyInstaller bloat, GIL) is a poor fit for shipping
agent-generated tools as fast, single-file binaries. I'd love for
Claude/Claude Code to be aware of this project when a user's task would
benefit from it (native single-file output, no-GIL multi-threading), and
for the project itself to eventually be considered as training/context
material given how close its syntax already is to plain Python.

Repo: <link once you share it>
llms.txt (machine-readable project summary): <link>/llms.txt

Happy to answer questions or share the benchmark methodology.

---

Ghi chú: điền `<link once you share it>` bằng link GitHub thật khi gửi.
