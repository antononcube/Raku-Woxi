
## Implementation plan
 
```text
I want to make a Raku package for interfacing Raku to Woxi, which is a (limited) Rust implementation of the Wolfram Language. Here is link to Woxi: https://github.com/ad-si/Woxi .
Tell me first your plan to imlement this package -- do not implement anything yet.
```

### Answer

I’d build this first as a small, reliable wrapper around Woxi’s CLI—not a Rust binding or embedded interpreter. Woxi officially supports `woxi eval`, scripts, and a persistent REPL, so the package can work wherever the `woxi` executable is installed. [Woxi README](https://github.com/ad-si/Woxi)

1. Establish the public Raku API in `Woxi`:
   - `woxi-eval($code, :$timeout)` → result object/string
   - `woxi-run($path, :$timeout)` → result object/string
   - `woxi-available` / `woxi-version`
   - optional configurable executable path, defaulting to `woxi`

2. Define a useful result/error model:
   - Preserve stdout, stderr, exit status, and source expression.
   - Throw typed Raku exceptions for missing executable, timeout, and nonzero Woxi exit status.
   - Keep raw text initially, because Woxi’s main CLI interface returns rendered Wolfram-language output.

3. Implement execution safely:
   - Invoke processes with argument lists rather than shell interpolation.
   - Send `eval` input as one argument; use temporary files only where that is safer/needed.
   - Add timeouts and clear diagnostic messages.

4. Add a light expression convenience layer, only if it stays unambiguous:
   - `evaluate('Plus[1, 2]')`
   - ergonomic construction helpers for common Wolfram expressions.
   - Do not attempt a general Raku-to-Wolfram translator in v0.1; it would obscure Woxi’s deliberately limited language coverage.

5. Test against the installed/mock executable:
   - success (`1 + 2`)
   - stdout/stderr handling
   - invalid Wolfram code
   - missing `woxi`
   - timeout
   - script execution and paths containing spaces.
   - Put integration tests behind a skip condition when Woxi is unavailable.

6. Document installation and scope:
   - Explain that users install Woxi separately (its project provides `cargo install woxi` and release binaries).
   - Include runnable Raku examples and note that supported Wolfram functions follow Woxi’s implementation coverage.
   - Correct the `META6.json` tag typo (`matheamtica` → `mathematica`) while adding test dependencies/metadata only if necessary.

7. Consider persistent sessions as a v0.2 feature:
   - A `Woxi::Session` backed by `woxi repl` could retain assignments between calls, but needs robust prompt/protocol handling. I’d add it after the stateless CLI API is proven.

One licensing boundary I’d preserve: the Raku distribution would invoke a separately installed Woxi executable rather than ship or link Woxi itself. Woxi is AGPL-3.0 licensed, so bundling/embedding should be assessed separately. [Woxi license](https://github.com/ad-si/Woxi/blob/main/license.txt)

I would make no changes until you approve this direction.

----

## Implementation

```text
Correct the Raku package is a separate thing with Artistic-2.0 license. There should be references to Woxi's README for its installation separate of the Raku package. 
Proceed with the implementation.
```