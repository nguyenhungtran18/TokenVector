# Changelog

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
