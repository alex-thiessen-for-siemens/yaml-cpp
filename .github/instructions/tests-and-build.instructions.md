---
applyTo: "test/**/*,CMakeLists.txt,cmake/**/*,BUILD.bazel,**/BUILD.bazel,MODULE.bazel,**/*.yml,**/*.yaml"
---

Put a regression in the narrowest existing test suite that owns the behavior.
Use the test helpers and exception assertions already present. Keep tests
deterministic, independent, and small enough to explain the boundary they
protect. Spec tests are reserved for examples taken directly from the YAML
specification.
Preserve existing test statements, indentation, and comments outside the
requested hunk. Do not normalize a whole touched test file to satisfy a
file-level formatter or static-analysis result. Findings on unchanged lines
are baseline findings; leave them intact and let the evaluation loop report
them separately from diagnostics introduced by the contribution.

For new source or public headers, check CMake source registration, Bazel
globs or targets, installation and package tests, and include dependencies.
Preserve the CMake 3.15 minimum and C++11 build. Consider static and shared
libraries, system and embedded GoogleTest, Windows runtime choices, and the
platforms in `.github/workflows/build.yml`.

Run the smallest relevant target first. Then use the evaluation skill for the
full local evidence selected for the contribution. Report unavailable tools
and user waivers separately from passing checks. Do not change CI merely to
make a local check green.
