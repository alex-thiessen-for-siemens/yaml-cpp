---
applyTo: "test/**/*,CMakeLists.txt,cmake/**/*,BUILD.bazel,**/BUILD.bazel,MODULE.bazel,**/*.yml,**/*.yaml"
---

Put a regression in the narrowest existing test suite that owns the behavior.
Use the test helpers and exception assertions already present. Keep tests
deterministic, independent, and small enough to explain the boundary they
protect. Spec tests are reserved for examples taken directly from the YAML
specification.
For a YAML-observable behavior change, add a private fixture and compare the
candidate result with a matching locally installed YAML implementation using
`/yaml-cpp-reference-check`. Record its version, schema, normalization, and
result in the private ledger. Do not add the fixture or adapter to the
upstream contribution, and do not use a network service as an oracle.
For parser- or event-level behavior, also build the private libyaml adapter
and record its parser-only scope separately from any native-value comparison.
Prefer the latest stable matching reference release available locally. When
the comparison passes, put a `Reference verification:` block in the commit
message body with every reference name, exact version, schema or layer, and
result. If freshness is waived, record that waiver in the ledger and body.

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
