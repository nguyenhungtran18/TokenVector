# Changelog

## [1.0.14] - 2026-11-12

### Changed

- Bundled compiler refreshed to TokenVector 1.0.14 (`tkvc-tv.exe`):
  `RepL` fast path for list repeat (`[x]*n`, total >= 64) — array doubling
  via `Array.Copy` + `_items`/`_size` reflection install; `[chunk]*200000`
  string build 0.99 -> 0.51 ms (~1.9x). `"".join(list[str])` unchanged
  (experimental JoinList reverted after .NET 10 JIT rejected it).
- Benchmark re-verified: gate 136/136, negative 44/44, inference 135/135,
  trainer 15/15, self-host build IL_IDENTICAL.

## [1.0.13] - 2026-11-11

### Changed

- Bundled compiler refreshed to TokenVector 1.0.13 (`tkvc-tv.exe` + `tkv_simd_native.dll`):
  `adamw_step_glm` takes a `coef` argument (clip-grad in one kernel pass),
  `zeros_list` single allocation, f-string `{n:5d}` / `list(str)` fixes,
  `--print-ret`, SIMD flash-attention SDPA AVX2 improvements.

## [1.0.12] - 2026-11-04

### Changed

- Bumped version to 1.0.12.

## [1.0.11] - 2026-10-18

### Added

- Initial release of the TokenVector VS Code extension.
- Syntax highlighting for `.tkv` files.
- Language configuration: auto-indent, brackets, comments.
- Snippets for common TokenVector constructs.
- `TokenVector: Build Current File` and `TokenVector: Build and Run Current File` commands.
- Settings: `compilerPath`, `extraArgs`, `saveBeforeBuild`.
