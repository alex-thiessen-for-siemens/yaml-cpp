#include "yaml-cpp/yaml.h"

#include "gtest/gtest.h"

#include <utility>

namespace {

struct MoveOnlyNonDefault {
  explicit MoveOnlyNonDefault(int value) : value(value) {}
  MoveOnlyNonDefault(const MoveOnlyNonDefault&) = delete;
  MoveOnlyNonDefault& operator=(const MoveOnlyNonDefault&) = delete;
  MoveOnlyNonDefault(MoveOnlyNonDefault&&) = default;
  MoveOnlyNonDefault& operator=(MoveOnlyNonDefault&&) = default;

  int value;
};

}  // namespace

namespace YAML {

template <>
struct convert<MoveOnlyNonDefault> {
  static auto decode(const Node& node) -> expected<MoveOnlyNonDefault> {
    return expected<MoveOnlyNonDefault>(node.as<int>());
  }
};

}  // namespace YAML

TEST(MoveOnlyConversionTest, ExpectedCanMoveEngagedValue) {
  YAML::expected<MoveOnlyNonDefault> source(42);
  YAML::expected<MoveOnlyNonDefault> moved(std::move(source));
  EXPECT_EQ(42, (*moved).value);
}

TEST(MoveOnlyConversionTest, NodeAsReturnsMoveOnlyValue) {
  YAML::Node node("42");
  const auto result = node.as<MoveOnlyNonDefault>();
  EXPECT_EQ(42, result.value);
}
