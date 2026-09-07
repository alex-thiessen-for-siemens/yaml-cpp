#include "directives.h"
#include "yaml-cpp/exceptions.h"

namespace YAML {
Directives::Directives() : version{true, 1, 2}, tags{} {}

std::string Directives::TranslateTagHandle(const std::string& handle,
                                           const Mark& mark) const {
  auto it = tags.find(handle);
  if (it == tags.end()) {
    if (handle == "!!")
      return "tag:yaml.org,2002:";
    if (handle == "!")
      return "!";
    throw ParserException(mark, ErrorMsg::UNDECLARED_TAG_HANDLE);
  }

  return it->second;
}
}  // namespace YAML
