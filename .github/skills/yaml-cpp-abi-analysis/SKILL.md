---
name: yaml-cpp-abi-analysis
description: Analyze yaml-cpp ABI and recompilation impact.
---

Use this skill for any contribution that changes a public header, exported
symbol, exported class, inline implementation, `CMakeLists.txt` version
property, visibility macro, installed include path, package boundary, or
standard-library type in a public signature or class layout. Use it before
editing and again before upstream readiness. For a source or test change with
no public or build-interface impact, record ABI analysis as not applicable
instead of running a broad survey.

## Compatibility model

Keep these questions separate:

* Does a consumer need to recompile because an included declaration, inline
  definition, template, enum, or class layout changed?
* Does a static-library consumer need to relink against a replacement
  archive?
* Can an already-compiled consumer link and run with the new shared library?
* Does the library's SONAME correctly declare the binary compatibility
  boundary?

An unchanged SONAME is not proof of ABI compatibility. A changed SONAME can
force downstream rebuilds even when the ABI is compatible. Public C++ class
layouts, inline code, exception types, virtual functions, mangled signatures,
data symbols, and exported standard-library types all require deliberate
review.

## Repository facts to verify

Do not treat these facts as a substitute for a current comparison:

* `CMakeLists.txt` currently derives `SOVERSION` from
  `PROJECT_VERSION_MAJOR.PROJECT_VERSION_MINOR`; patch releases retain the
  minor-line SONAME.
* `yaml-cpp/yaml.h` exports `node/impl.h` and
  `node/detail/impl.h`, so consumer recompilation is more common than the
  SONAME policy alone suggests.
* `Binary`, `ostream_wrapper`, `Node`, and installed `detail` types expose
  implementation or STL-backed state that can affect object layout and
  cross-toolchain ABI.
* The 0.6.2 to 0.6.3 history contains the `empty_scalar` data-symbol to
  function-symbol change and the `RegEx` operator change while retaining the
  `0.6` SONAME. This is a known historical warning, not a waiver for a new
  change.
* `abi-and-issues.asciidoc` records the supporting release, symbol-screening,
  batching, and hardening study. Use it as context, then recheck the current
  baseline and tool results for each contribution.
* Upstream issues `jbeder/yaml-cpp#789`, `#835`, `#1102`, `#1317`, and
  `#642` document downstream ABI failures, reactive repairs, unnecessary
  SONAME rebuilds, and Windows DLL layout warnings.

## Analysis workflow

1. Record the intended base, changed files, public headers or symbols
   affected, compatibility promise, and whether the user authorizes an ABI
   transition in the private evidence ledger.
2. Inspect `CMakeLists.txt`, `dll.h`, `yaml.h`, the affected public headers,
   installation/package rules, and the complete history from the intended
   baseline. Check both declarations and inline definitions.
3. Decide whether the contribution is intended to preserve ABI. If it does,
   reject unexplained changes to public object layout, exported signatures,
   vtables, data symbols, exception types, or inline contracts. If it
   intentionally breaks ABI, require an explicit ABI version/SOVERSION
   decision and keep the change off an upstream-compatible branch until that
   decision is made.
4. Prefer a shared-library comparison against the last released baseline
   using `abidiff` or `abipkgdiff` when either tool is installed. Record the
   exact compiler, standard library, build flags, shared/static options,
   target architecture, baseline artifact, candidate artifact, tool version,
   command, and result. A missing tool is a coverage limitation, not a pass;
   ask the user whether to install it or explicitly waive the ABI check before
   continuing. Do not install host software silently.
5. Use `readelf -d` to record SONAMEs and a demangled exported-symbol list as
   a fast diagnostic when libabigail is unavailable. Treat symbol presence as
   incomplete evidence: it does not prove class-layout, inline, calling
   convention, or platform DLL compatibility.
6. For a public layout or header change, add a focused old-header/new-library
   or new-header/old-library consumer probe when the compatibility contract
   requires it. Exercise construction, destruction, copying, exceptions,
   virtual dispatch, and representative public calls across the boundary.
7. Consider whether a smaller solution avoids the ABI change: an existing
   out-of-line function, a deprecated forwarding symbol, an opaque handle, or
   a private implementation object. Do not start a broad Pimpl redesign as a
   drive-by repair; record allocation, performance, ownership, allocator, and
   migration costs.
8. Record the conclusion as one of `ABI preserved`, `ABI transition
   authorized`, `ABI not applicable`, or `ABI evidence incomplete`. Include
   unresolved platform limitations and the required SONAME or packaging
   action. Re-read the ledger before implementation and before publication.

Historical tag builds may require temporary build-system compatibility edits.
Keep those edits outside the repository and describe them in the ledger.
Never call a symbol-only screen a complete ABI proof, and never claim Linux
or emulated results prove native Windows, macOS, or ARM compatibility.
