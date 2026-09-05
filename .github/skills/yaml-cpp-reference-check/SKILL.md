---
name: yaml-cpp-reference-check
description: Compare a yaml-cpp behavior change with a locally installed YAML implementation without network access or repository artifacts.
---

Use this skill for every behavior change that is observable through YAML
syntax, tags, schemas, serialization, parsing, or public conversion behavior.
First classify the behavior and identify the exact YAML version, schema, tags,
and observable result under test. YAML has no single implementation that is
authoritative for every schema and extension, so do not call an implementation
“the reference” without recording why its semantics match the case.

Choose a locally installed implementation with the matching semantics, such as
PyYAML or Ruby Psych when their version and schema are suitable. Do not fetch a
package, call a hosted service, or add an adapter to the contribution branch.
Keep the fixture and adapters in private session artifacts or `/tmp`.

LibYAML is the YAML community's established C parser and emitter
implementation, often used as a parser/emitter reference. Its documented
scope stops at parsing and presenting: it does not resolve tags or construct
native values. For parser-, event-, scalar-, or emitter-level changes, build
the private
`libyaml-event-adapter.c` with `build-libyaml-adapter.sh` and use its
canonical event stream as an additional local oracle. Record the libyaml
version and the layer it covers. For a change that also observes resolved or
constructed values, such as YAML 1.1 `!!binary`, run both checks: libyaml
cross-validates syntax, tags, and scalar content, while PyYAML or another
matching constructor cross-validates the native value. Do not treat libyaml's
parser result as evidence that a native value was constructed correctly.

Create two executable local adapters with the same contract:

* argument 1 is the fixture path;
* stdout is a deterministic, canonical representation of the observable
  result; and
* non-zero exit means the adapter could not evaluate the fixture.

The candidate adapter exercises the changed yaml-cpp behavior. The reference
adapter exercises the selected local implementation. Use
`run-reference-check.sh` to invoke both directly and compare stdout. The
runner unsets proxy variables, sets `YAML_CPP_REFERENCE_LOCAL_ONLY=1`, never
installs dependencies, and never uploads the fixture or result. Adapters must
honor that local-only contract and must not open network connections.

Record the fixture, adapter paths, implementation versions, schema,
normalization rule, command, and result in the private evidence ledger. Record
parser-only libyaml evidence separately from native-value evidence. A mismatch
is a failure requiring diagnosis, not permission to weaken the test. If no
local implementation has matching semantics, record the reason and an
explicit reference-check limitation; do not claim that the behavior is
cross-validated.

For yaml-cpp-only APIs that cannot be represented by any YAML input, record
“not applicable” with the reason and retain the owning unit, safety, and
evaluation evidence. Do not invent a reference comparison by silently changing
the behavior under test.
