#include "yaml-cpp/yaml.h"

#include "gtest/gtest.h"

TEST(NullConversionTest, NullNodeConvertsToNode) {
  YAML::Node node(YAML::NodeType::Null);
  EXPECT_EQ(YAML::NodeType::Null, node.as<YAML::Node>().Type());
}

TEST(NullConversionTest, NullNodeConvertsToNull) {
  YAML::Node node(YAML::NodeType::Null);
  EXPECT_EQ(YAML::_Null{}, node.as<YAML::_Null>());
}
