#ifndef REGEX_YAML_CONST_H_62B23520_7C8E_11DE_8A39_0800200C9A66
#define REGEX_YAML_CONST_H_62B23520_7C8E_11DE_8A39_0800200C9A66

#if defined(_MSC_VER) ||                                            \
    (defined(__GNUC__) && (__GNUC__ == 3 && __GNUC_MINOR__ >= 4) || \
     (__GNUC__ >= 4))
#pragma once
#endif

#include <cstddef>
#include <cstdint>
#include <string>

#include "streamcharsource.h"
#include "stringsource.h"

namespace YAML {
template <int Byte>
struct ConstByteMask {
  static constexpr std::uint64_t Word0() {
    return Byte < 64 ? (std::uint64_t(1) << Byte) : 0;
  }
  static constexpr std::uint64_t Word1() {
    return Byte >= 64 && Byte < 128 ? (std::uint64_t(1) << (Byte - 64)) : 0;
  }
  static constexpr std::uint64_t Word2() {
    return Byte >= 128 && Byte < 192 ? (std::uint64_t(1) << (Byte - 128)) : 0;
  }
  static constexpr std::uint64_t Word3() {
    return Byte >= 192 && Byte < 256 ? (std::uint64_t(1) << (Byte - 192)) : 0;
  }
};

template <int... Bytes>
struct ConstCharSetMask;

template <>
struct ConstCharSetMask<> {
  static constexpr std::uint64_t Word0() { return 0; }
  static constexpr std::uint64_t Word1() { return 0; }
  static constexpr std::uint64_t Word2() { return 0; }
  static constexpr std::uint64_t Word3() { return 0; }
};

template <int Byte, int... Bytes>
struct ConstCharSetMask<Byte, Bytes...> {
  static constexpr std::uint64_t Word0() {
    return ConstByteMask<Byte>::Word0() | ConstCharSetMask<Bytes...>::Word0();
  }
  static constexpr std::uint64_t Word1() {
    return ConstByteMask<Byte>::Word1() | ConstCharSetMask<Bytes...>::Word1();
  }
  static constexpr std::uint64_t Word2() {
    return ConstByteMask<Byte>::Word2() | ConstCharSetMask<Bytes...>::Word2();
  }
  static constexpr std::uint64_t Word3() {
    return ConstByteMask<Byte>::Word3() | ConstCharSetMask<Bytes...>::Word3();
  }
  static constexpr bool Contains(unsigned char byte) {
    return byte < 64    ? (Word0() & (std::uint64_t(1) << byte)) != 0
           : byte < 128 ? (Word1() & (std::uint64_t(1) << (byte - 64))) != 0
           : byte < 192 ? (Word2() & (std::uint64_t(1) << (byte - 128))) != 0
                        : (Word3() & (std::uint64_t(1) << (byte - 192))) != 0;
  }
};

struct ConstEmpty {
  static int Match(const StringCharSource& source) { return !source ? 0 : -1; }

  static int Match(const StreamCharSource& source) {
    return static_cast<bool>(source) && source[0] == Stream::eof() ? 0 : -1;
  }

  template <typename Source>
  static int Match(const Source& source) {
    return static_cast<bool>(source) ? -1 : 0;
  }

  static constexpr bool MatchesEmpty() { return true; }
  static constexpr bool MatchesOneChar(char) { return false; }
};

template <int Byte>
struct ConstByte {
  template <typename Source>
  static int Match(const Source& source) {
    return static_cast<bool>(source) &&
                   static_cast<unsigned char>(source[0]) == Byte
               ? 1
               : -1;
  }

  static constexpr bool MatchesEmpty() { return false; }
  static constexpr bool MatchesOneChar(char ch) {
    return static_cast<unsigned char>(ch) == Byte;
  }
};

template <int First, int Last>
struct ConstRange {
  template <typename Source>
  static int Match(const Source& source) {
    return static_cast<bool>(source) &&
                   static_cast<unsigned char>(source[0]) >= First &&
                   static_cast<unsigned char>(source[0]) <= Last
               ? 1
               : -1;
  }

  static constexpr bool MatchesEmpty() { return false; }
  static constexpr bool MatchesOneChar(char ch) {
    return static_cast<unsigned char>(ch) >= First &&
           static_cast<unsigned char>(ch) <= Last;
  }
};

template <int... Bytes>
struct ConstCharSet {
  template <typename Source>
  static int Match(const Source& source) {
    return static_cast<bool>(source) &&
                   ConstCharSetMask<Bytes...>::Contains(
                       static_cast<unsigned char>(source[0]))
               ? 1
               : -1;
  }

  static constexpr bool MatchesEmpty() { return false; }
  static constexpr bool MatchesOneChar(char ch) {
    return ConstCharSetMask<Bytes...>::Contains(static_cast<unsigned char>(ch));
  }
};

template <typename Left, typename Right>
struct ConstOr {
  template <typename Source>
  static int Match(const Source& source) {
    const int left = Left::Match(source);
    return left >= 0 ? left : Right::Match(source);
  }

  static constexpr bool MatchesEmpty() {
    return Left::MatchesEmpty() || Right::MatchesEmpty();
  }
  static constexpr bool MatchesOneChar(char ch) {
    return Left::MatchesOneChar(ch) || Right::MatchesOneChar(ch);
  }
};

template <typename Left, typename Right>
struct ConstAnd {
  template <typename Source>
  static int Match(const Source& source) {
    const int left = Left::Match(source);
    return left >= 0 && Right::Match(source) >= 0 ? left : -1;
  }

  static constexpr bool MatchesEmpty() {
    return Left::MatchesEmpty() && Right::MatchesEmpty();
  }
  static constexpr bool MatchesOneChar(char ch) {
    return Left::MatchesOneChar(ch) && Right::MatchesOneChar(ch);
  }
};

template <typename Pattern>
struct ConstNot {
  template <typename Source>
  static int Match(const Source& source) {
    return Pattern::Match(source) >= 0 ? -1 : 1;
  }

  static constexpr bool MatchesEmpty() { return false; }
  static constexpr bool MatchesOneChar(char ch) {
    return !Pattern::MatchesOneChar(ch);
  }
};

template <typename Left, typename Right>
struct ConstSeq {
  template <typename Source>
  static int Match(const Source& source) {
    const int left = Left::Match(source);
    if (left < 0)
      return -1;
    const int right = Right::Match(source + left);
    return right < 0 ? -1 : left + right;
  }

  static constexpr bool MatchesEmpty() {
    return Left::MatchesEmpty() && Right::MatchesEmpty();
  }
  static constexpr bool MatchesOneChar(char ch) {
    return (Left::MatchesEmpty() && Right::MatchesOneChar(ch)) ||
           (Left::MatchesOneChar(ch) && Right::MatchesEmpty());
  }
};

template <typename Pattern>
struct ConstRegExPattern {};

template <typename Pattern>
struct ConstRegExInvoker {
  static int MatchString(const StringCharSource& source) {
    return Pattern::Match(source);
  }

  static int MatchStream(const Stream& stream) {
    return Pattern::Match(StreamCharSource(stream));
  }

  static int MatchStreamSource(const StreamCharSource& source) {
    return Pattern::Match(source);
  }

  static constexpr bool MatchChar(char ch) {
    return Pattern::MatchesOneChar(ch);
  }
};

class ConstRegEx {
 public:
  typedef int (*StringMatcher)(const StringCharSource&);
  typedef int (*StreamMatcher)(const Stream&);
  typedef int (*StreamSourceMatcher)(const StreamCharSource&);
  typedef bool (*CharMatcher)(char);

  template <typename Pattern>
  constexpr explicit ConstRegEx(ConstRegExPattern<Pattern>)
      : m_match_string(&ConstRegExInvoker<Pattern>::MatchString),
        m_match_stream(&ConstRegExInvoker<Pattern>::MatchStream),
        m_match_stream_source(&ConstRegExInvoker<Pattern>::MatchStreamSource),
        m_match_char(&ConstRegExInvoker<Pattern>::MatchChar) {}

  int Match(const std::string& str) const {
    return Match(StringCharSource(str.c_str(), str.size()));
  }
  int Match(const StringCharSource& source) const {
    return m_match_string(source);
  }
  int Match(const Stream& stream) const { return m_match_stream(stream); }
  int Match(const StreamCharSource& source) const {
    return m_match_stream_source(source);
  }

  constexpr bool Matches(char ch) const { return m_match_char(ch); }
  bool Matches(const std::string& str) const { return Match(str) >= 0; }
  bool Matches(const StringCharSource& source) const {
    return Match(source) >= 0;
  }
  bool Matches(const Stream& stream) const { return Match(stream) >= 0; }
  bool Matches(const StreamCharSource& source) const {
    return Match(source) >= 0;
  }

 private:
  StringMatcher m_match_string;
  StreamMatcher m_match_stream;
  StreamSourceMatcher m_match_stream_source;
  CharMatcher m_match_char;
};

template <typename Pattern>
constexpr ConstRegEx MakeConstRegEx() {
  return ConstRegEx(ConstRegExPattern<Pattern>());
}
}  // namespace YAML

#endif  // REGEX_YAML_CONST_H_62B23520_7C8E_11DE_8A39_0800200C9A66
