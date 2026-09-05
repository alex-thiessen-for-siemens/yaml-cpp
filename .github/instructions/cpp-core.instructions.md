---
applyTo: "src/**/*,include/**/*,**/*.h,**/*.hpp,**/*.cc,**/*.cpp,**/*.cxx"
---

For C++ changes, preserve C++11 compilation unless the task explicitly changes
the supported standard. Follow the root `.clang-format` and nearby naming and
layout. Keep public headers self-contained and avoid adding dependencies or
symbols that change ABI without a deliberate compatibility decision.

Trace ownership from creation through destruction. Prefer the ownership
patterns already used in this repository and make the owner and lifetime
visible. Check empty-container behavior, iterator and proxy lifetimes,
invalidated references, array bounds, signed conversions, integer overflow,
character classification casts, stream state flags, and exception paths.

For scanner, parser, emitter, and stream code, write down the relevant state
invariant before editing. Check every push/pop, retry, early return, EOF path,
and failure path against that invariant. A defensive guard is not a substitute
for fixing the state transition that made the guard necessary.

Match existing exception types, marks, messages, and `noexcept` behavior. Do
not catch broad exceptions or turn a failure into a success-shaped fallback.
When a public behavior changes, add a regression at the owning test layer and
check both the changed case and nearby valid behavior.
