# Quality calibration

This rubric calibrates the private setup against accepted yaml-cpp changes. It
is not a claim that a model has passed a benchmark.

| Upstream example | What the patch protected | Evidence to require |
| --- | --- | --- |
| #1482, empty `YAML::Binary` | `data()` must not form an invalid reference for an empty vector | One focused code change and an empty-value test |
| #1481, tagged multi-document emission | The emitter must not start a document twice after a tag | A state-transition explanation and repeated tagged-document test |
| #1476, literal scalar with a tag | An unverified simple key must not pop an unrelated indentation stack entry | A local guard plus malformed-input test |
| #1486, failed input streams | Initial, partial, and exception-enabled stream failures must be rejected while empty EOF remains valid | Boundary tests, explicit exception behavior, and RAII ownership |
| #1398, truncated Base64 | Invalid encoded length must not be accepted as complete input | A malformed-input test without weakening valid decoding |

A Luna Medium-quality contribution must identify the affected layer and
invariant, preserve valid boundary behavior, add the owning test that prevents
regressions, pass
the selected deterministic checks, and leave no unresolved high-confidence
review blocker. It must also preserve pre-existing lines outside the requested
hunks; a touched file is not permission to normalize unrelated code. A
smaller patch is preferred when it provides the same evidence, and any
feature-introduced review repair must be folded into the feature history before
publication. When the behavior is YAML-observable, it must also have a
matching local-reference comparison with recorded schema and normalization;
an unavailable matching implementation is an explicit limitation. Parser- or
event-level behavior should add separate libyaml C evidence when available,
while constructed-value behavior still requires a matching semantic
implementation. When a reference comparison passes, the commit body must name
each reference's exact version, schema or layer, and result; the latest stable
matching release is the default.
