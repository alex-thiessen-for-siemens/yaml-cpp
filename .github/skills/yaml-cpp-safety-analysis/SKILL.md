---
name: yaml-cpp-safety-analysis
description: Perform a focused, read-only safety review of yaml-cpp C++ changes for memory, lifetime, parser-state, malformed-input, and compatibility defects.
---

Review the actual diff and the affected call chain. Do not review the whole
repository and do not propose cosmetic rewrites.

Check:

* ownership transfer, destruction order, raw pointer aliases, array
  allocation, empty containers, dangling references, and iterator or proxy
  lifetimes;
* indexing and arithmetic bounds, signed and unsigned conversions, overflow,
  truncation, character classification casts, and invalid assumptions about
  encoded input;
* stream `eofbit`, `failbit`, `badbit`, exception-enabled buffers, partial
  reads, and the distinction between empty input and failed input;
* scanner, parser, emitter, and indentation-stack invariants across normal,
  repeated, empty, EOF, malformed, and exception paths;
* public-header self-containment, exception destructors, `noexcept`, ABI
  visibility, iterator traits, and C++11 compilation;
* static and shared library behavior, package installation, Bazel consumers,
  and tests that exercise the changed public behavior.

For every finding, give severity, file and line, concrete trigger, violated
invariant, and a minimal repair. Distinguish a definite defect from a question
that needs more evidence. A passing test does not clear an untested lifetime
or state path. Do not edit files. Return a short report and update the ledger
with the reviewed scope and any blocker.
