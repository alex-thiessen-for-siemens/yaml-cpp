#ifndef EXP_H_62B23520_7C8E_11DE_8A39_0800200C9A66
#define EXP_H_62B23520_7C8E_11DE_8A39_0800200C9A66

#if defined(_MSC_VER) ||                                            \
    (defined(__GNUC__) && (__GNUC__ == 3 && __GNUC_MINOR__ >= 4) || \
     (__GNUC__ >= 4))  // GCC supports "pragma once" correctly since 3.4
#pragma once
#endif

#include <ios>
#include <string>

#include "regex_yaml.h"
#include "stream.h"

namespace YAML {
////////////////////////////////////////////////////////////////////////////////
// Here we store a bunch of expressions for matching different parts of the
// file.

namespace Exp {
namespace Patterns {
using Empty = YAML::Empty;
using Space = CharSet<' '>;
using Tab = CharSet<'\t'>;
using Blank = CharSet<' ', '\t'>;
using LineFeed = Byte<'\n'>;
using CarriageReturnLineFeed = Seq<Byte<'\r'>, Byte<'\n'>>;
using Break = Or<LineFeed, CarriageReturnLineFeed, Byte<'\r'>>;
using BlankOrBreak = Or<Blank, Break>;
using Digit = Range<'0', '9'>;
using Alpha = Or<Range<'a', 'z'>, Range<'A', 'Z'>>;
using AlphaNumeric = Or<Alpha, Digit>;
using Word = Or<AlphaNumeric, Byte<'-'>>;
using Hex = Or<Digit, Range<'A', 'F'>, Range<'a', 'f'>>;

using NotPrintableBytes =
    CharSet<'\x01', '\x02', '\x03', '\x04', '\x05', '\x06', '\a', '\b', '\v',
            '\f', '\x7F'>;
using NotPrintableUtf8Tail = Or<Range<0x80, 0x84>, Range<0x86, 0x9F>>;
using NotPrintableUtf8 = Seq<Byte<0xC2>, NotPrintableUtf8Tail>;
using NotPrintable =
    Or<Byte<0>, NotPrintableBytes, Range<0x0E, 0x1F>, NotPrintableUtf8>;
using Utf8ByteOrderMark = Seq<Byte<0xEF>, Byte<0xBB>, Byte<0xBF>>;

using DocumentStartPrefix = Seq<Byte<'-'>, Byte<'-'>, Byte<'-'>>;
using DocumentEndPrefix = Seq<Byte<'.'>, Byte<'.'>, Byte<'.'>>;
using DocumentMarkerSuffix = Or<BlankOrBreak, Empty>;
using DocumentStart = Seq<DocumentStartPrefix, DocumentMarkerSuffix>;
using DocumentEnd = Seq<DocumentEndPrefix, DocumentMarkerSuffix>;
using DocumentIndicator = Or<DocumentStart, DocumentEnd>;
using BlockEntry = Seq<Byte<'-'>, DocumentMarkerSuffix>;
using Key = Seq<Byte<'?'>, BlankOrBreak>;
using KeyInFlow = Key;
using Value = Seq<Byte<':'>, DocumentMarkerSuffix>;
using FlowValueTerminators = CharSet<',', ']', '}'>;
using ValueInFlow = Seq<Byte<':'>, Or<BlankOrBreak, FlowValueTerminators>>;
using ValueInJSONFlow = Byte<':'>;
using Ampersand = Byte<'&'>;
using Comment = Byte<'#'>;
using AnchorTerminators = CharSet<'[', ']', '{', '}', ','>;
using Anchor = Not<Or<AnchorTerminators, BlankOrBreak>>;
using AnchorEnd =
    Or<CharSet<'?', ':', ',', ']', '}', '%', '@', 0x60>, BlankOrBreak>;

using UriCharacters =
    CharSet<'#', ';', '/', '?', ':', '@', '&', '=', '+', '$', ',', '_', '.',
            '!', '~', '*', '\'', '(', ')', '[', ']'>;
using TagCharacters = CharSet<'#', ';', '/', '?', ':', '@', '&', '=', '+', '$',
                              '_', '.', '~', '*', '\'', '(', ')'>;
using PercentEncoded = Seq<Byte<'%'>, Hex, Hex>;
using Uri = Or<Word, UriCharacters, PercentEncoded>;
using Tag = Or<Word, TagCharacters, PercentEncoded>;

using PlainScalarTerminators =
    CharSet<',', '[', ']', '{', '}', '#', '&', '*', '!', '|', '>', '\'', '"',
            '%', '@', 0x60>;
using PlainScalarIndicators = CharSet<'-', '?', ':'>;
using PlainScalarRejection =
    Or<BlankOrBreak, PlainScalarTerminators,
       Seq<PlainScalarIndicators, Or<BlankOrBreak, Empty>>>;
using PlainScalar = Not<PlainScalarRejection>;

using PlainScalarFlowTerminators =
    CharSet<'?', ',', '[', ']', '{', '}', '#', '&', '*', '!', '|', '>', '\'',
            '"', '%', '@', 0x60>;
using PlainScalarFlowIndicators = CharSet<'-', ':'>;
using PlainScalarFlowRejection =
    Or<BlankOrBreak, PlainScalarFlowTerminators,
       Seq<PlainScalarFlowIndicators, Or<Blank, Empty>>>;
using PlainScalarInFlow = Not<PlainScalarFlowRejection>;

using EndScalar = Seq<Byte<':'>, DocumentMarkerSuffix>;
using FlowScalarTerminators = CharSet<',', '?', '[', ']', '{', '}'>;
using EndScalarInFlowPrefix =
    Seq<Byte<':'>, Or<BlankOrBreak, Empty, FlowValueTerminators>>;
using EndScalarInFlow = Or<EndScalarInFlowPrefix, FlowScalarTerminators>;
using CommentAfterBreak = Seq<BlankOrBreak, Comment>;
using ScanScalarEndInFlow = Or<EndScalarInFlow, CommentAfterBreak>;
using ScanScalarEnd = Or<EndScalar, CommentAfterBreak>;
using EscSingleQuote = Seq<Byte<'\''>, Byte<'\''>>;
using EscBreak = Seq<Byte<'\\'>, Break>;
using SingleQuoteEnd = And<Byte<'\''>, Not<EscSingleQuote>>;
using DoubleQuoteEnd = Byte<'"'>;
using ChompIndicator = CharSet<'+', '-'>;
using Chomp = Or<Seq<ChompIndicator, Digit>, Seq<Digit, ChompIndicator>,
                 ChompIndicator, Digit>;
using DisallowedWhitespace = Or<Tab, Ampersand>;
using DisallowedBreak = Or<Break, DisallowedWhitespace>;
using DisallowedEncoding = Or<Utf8ByteOrderMark, DisallowedBreak>;
using DisallowedCharacters = Or<NotPrintable, DisallowedEncoding>;
using DisallowedAfterComment = Or<CommentAfterBreak, DisallowedCharacters>;
using DisallowedFlow = Or<EndScalarInFlow, DisallowedAfterComment>;
using DisallowedBlock = Or<EndScalar, DisallowedAfterComment>;
}  // namespace Patterns

template <typename Pattern>
inline const RegEx& Matcher() {
  static constexpr RegEx expression = MakeRegEx<Pattern>();
  return expression;
}

inline const RegEx& Empty() { return Matcher<Patterns::Empty>(); }
inline const RegEx& Space() { return Matcher<Patterns::Space>(); }
inline const RegEx& Tab() { return Matcher<Patterns::Tab>(); }
inline const RegEx& Blank() { return Matcher<Patterns::Blank>(); }
inline const RegEx& Break() { return Matcher<Patterns::Break>(); }
inline const RegEx& BlankOrBreak() { return Matcher<Patterns::BlankOrBreak>(); }
inline const RegEx& Digit() { return Matcher<Patterns::Digit>(); }
inline const RegEx& Alpha() { return Matcher<Patterns::Alpha>(); }
inline const RegEx& AlphaNumeric() { return Matcher<Patterns::AlphaNumeric>(); }
inline const RegEx& Word() { return Matcher<Patterns::Word>(); }
inline const RegEx& Hex() { return Matcher<Patterns::Hex>(); }
inline const RegEx& NotPrintable() { return Matcher<Patterns::NotPrintable>(); }
inline const RegEx& Utf8_ByteOrderMark() {
  return Matcher<Patterns::Utf8ByteOrderMark>();
}
inline const RegEx& DocStart() { return Matcher<Patterns::DocumentStart>(); }
inline const RegEx& DocEnd() { return Matcher<Patterns::DocumentEnd>(); }
inline const RegEx& DocIndicator() {
  return Matcher<Patterns::DocumentIndicator>();
}
inline const RegEx& BlockEntry() { return Matcher<Patterns::BlockEntry>(); }
inline const RegEx& Key() { return Matcher<Patterns::Key>(); }
inline const RegEx& KeyInFlow() { return Matcher<Patterns::KeyInFlow>(); }
inline const RegEx& Value() { return Matcher<Patterns::Value>(); }
inline const RegEx& ValueInFlow() { return Matcher<Patterns::ValueInFlow>(); }
inline const RegEx& ValueInJSONFlow() {
  return Matcher<Patterns::ValueInJSONFlow>();
}
inline const RegEx& Ampersand() { return Matcher<Patterns::Ampersand>(); }
inline const RegEx& Comment() { return Matcher<Patterns::Comment>(); }
inline const RegEx& Anchor() { return Matcher<Patterns::Anchor>(); }
inline const RegEx& AnchorEnd() { return Matcher<Patterns::AnchorEnd>(); }
inline const RegEx& URI() { return Matcher<Patterns::Uri>(); }
inline const RegEx& Tag() { return Matcher<Patterns::Tag>(); }
inline const RegEx& PlainScalar() { return Matcher<Patterns::PlainScalar>(); }
inline const RegEx& PlainScalarInFlow() {
  return Matcher<Patterns::PlainScalarInFlow>();
}
inline const RegEx& EndScalar() { return Matcher<Patterns::EndScalar>(); }
inline const RegEx& EndScalarInFlow() {
  return Matcher<Patterns::EndScalarInFlow>();
}
inline const RegEx& ScanScalarEndInFlow() {
  return Matcher<Patterns::ScanScalarEndInFlow>();
}
inline const RegEx& ScanScalarEnd() {
  return Matcher<Patterns::ScanScalarEnd>();
}
inline const RegEx& EscSingleQuote() {
  return Matcher<Patterns::EscSingleQuote>();
}
inline const RegEx& EscBreak() { return Matcher<Patterns::EscBreak>(); }
inline const RegEx& SingleQuoteEnd() {
  return Matcher<Patterns::SingleQuoteEnd>();
}
inline const RegEx& DoubleQuoteEnd() {
  return Matcher<Patterns::DoubleQuoteEnd>();
}
inline const RegEx& ChompIndicator() {
  return Matcher<Patterns::ChompIndicator>();
}
inline const RegEx& Chomp() { return Matcher<Patterns::Chomp>(); }
inline const RegEx& DisallowedFlow() {
  return Matcher<Patterns::DisallowedFlow>();
}
inline const RegEx& DisallowedBlock() {
  return Matcher<Patterns::DisallowedBlock>();
}

// and some functions
std::string Escape(Stream& in);
}  // namespace Exp

namespace Keys {
const char Directive = '%';
const char FlowSeqStart = '[';
const char FlowSeqEnd = ']';
const char FlowMapStart = '{';
const char FlowMapEnd = '}';
const char FlowEntry = ',';
const char Alias = '*';
const char Anchor = '&';
const char Tag = '!';
const char LiteralScalar = '|';
const char FoldedScalar = '>';
const char VerbatimTagStart = '<';
const char VerbatimTagEnd = '>';
}  // namespace Keys
}  // namespace YAML

#endif  // EXP_H_62B23520_7C8E_11DE_8A39_0800200C9A66
