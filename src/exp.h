#ifndef EXP_H_62B23520_7C8E_11DE_8A39_0800200C9A66
#define EXP_H_62B23520_7C8E_11DE_8A39_0800200C9A66

#if defined(_MSC_VER) ||                                            \
    (defined(__GNUC__) && (__GNUC__ == 3 && __GNUC_MINOR__ >= 4) || \
     (__GNUC__ >= 4))  // GCC supports "pragma once" correctly since 3.4
#pragma once
#endif

#include <ios>
#include <string>

#include "regex_yaml_const.h"
#include "stream.h"

namespace YAML {
////////////////////////////////////////////////////////////////////////////////
// Here we store a bunch of expressions for matching different parts of the
// file.

namespace Exp {
namespace Patterns {
typedef ConstEmpty Empty;
typedef ConstCharSet<' '> Space;
typedef ConstCharSet<'\t'> Tab;
typedef ConstCharSet<' ', '\t'> Blank;
typedef ConstByte<'\n'> LineFeed;
typedef ConstSeq<ConstByte<'\r'>, ConstByte<'\n'>> CarriageReturnLineFeed;
typedef ConstOr<LineFeed, ConstOr<CarriageReturnLineFeed, ConstByte<'\r'>>>
    Break;
typedef ConstOr<Blank, Break> BlankOrBreak;
typedef ConstRange<'0', '9'> Digit;
typedef ConstOr<ConstRange<'a', 'z'>, ConstRange<'A', 'Z'>> Alpha;
typedef ConstOr<Alpha, Digit> AlphaNumeric;
typedef ConstOr<AlphaNumeric, ConstByte<'-'>> Word;
typedef ConstOr<Digit, ConstOr<ConstRange<'A', 'F'>, ConstRange<'a', 'f'>>> Hex;

typedef ConstCharSet<1, 2, 3, 4, 5, 6, 7, 8, 0x0B, 0x0C, 0x7F>
    NotPrintableBytes;
typedef ConstOr<ConstRange<0x80, 0x84>, ConstRange<0x86, 0x9F>>
    NotPrintableUtf8Tail;
typedef ConstSeq<ConstByte<0xC2>, NotPrintableUtf8Tail> NotPrintableUtf8;
typedef ConstOr<ConstByte<0>,
                ConstOr<NotPrintableBytes,
                        ConstOr<ConstRange<0x0E, 0x1F>, NotPrintableUtf8>>>
    NotPrintable;
typedef ConstSeq<ConstByte<0xEF>, ConstSeq<ConstByte<0xBB>, ConstByte<0xBF>>>
    Utf8ByteOrderMark;

typedef ConstSeq<ConstByte<'-'>, ConstSeq<ConstByte<'-'>, ConstByte<'-'>>>
    DocumentStartPrefix;
typedef ConstSeq<ConstByte<'.'>, ConstSeq<ConstByte<'.'>, ConstByte<'.'>>>
    DocumentEndPrefix;
typedef ConstOr<BlankOrBreak, Empty> DocumentMarkerSuffix;
typedef ConstSeq<DocumentStartPrefix, DocumentMarkerSuffix> DocumentStart;
typedef ConstSeq<DocumentEndPrefix, DocumentMarkerSuffix> DocumentEnd;
typedef ConstOr<DocumentStart, DocumentEnd> DocumentIndicator;
typedef ConstSeq<ConstByte<'-'>, DocumentMarkerSuffix> BlockEntry;
typedef ConstSeq<ConstByte<'?'>, BlankOrBreak> Key;
typedef Key KeyInFlow;
typedef ConstSeq<ConstByte<':'>, DocumentMarkerSuffix> Value;
typedef ConstCharSet<',', ']', '}'> FlowValueTerminators;
typedef ConstSeq<ConstByte<':'>, ConstOr<BlankOrBreak, FlowValueTerminators>>
    ValueInFlow;
typedef ConstByte<':'> ValueInJSONFlow;
typedef ConstByte<'&'> Ampersand;
typedef ConstByte<'#'> Comment;
typedef ConstCharSet<'[', ']', '{', '}', ','> AnchorTerminators;
typedef ConstNot<ConstOr<AnchorTerminators, BlankOrBreak>> Anchor;
typedef ConstOr<ConstCharSet<'?', ':', ',', ']', '}', '%', '@', 0x60>,
                BlankOrBreak>
    AnchorEnd;

typedef ConstCharSet<'#', ';', '/', '?', ':', '@', '&', '=', '+', '$', ',', '_',
                     '.', '!', '~', '*', '\'', '(', ')', '[', ']'>
    UriCharacters;
typedef ConstCharSet<'#', ';', '/', '?', ':', '@', '&', '=', '+', '$', '_', '.',
                     '~', '*', '\'', '(', ')'>
    TagCharacters;
typedef ConstSeq<ConstByte<'%'>, ConstSeq<Hex, Hex>> PercentEncoded;
typedef ConstOr<Word, ConstOr<UriCharacters, PercentEncoded>> Uri;
typedef ConstOr<Word, ConstOr<TagCharacters, PercentEncoded>> Tag;

typedef ConstCharSet<',', '[', ']', '{', '}', '#', '&', '*', '!', '|', '>',
                     '\'', '"', '%', '@', 0x60>
    PlainScalarTerminators;
typedef ConstCharSet<'-', '?', ':'> PlainScalarIndicators;
typedef ConstOr<
    BlankOrBreak,
    ConstOr<PlainScalarTerminators,
            ConstSeq<PlainScalarIndicators, ConstOr<BlankOrBreak, Empty>>>>
    PlainScalarRejection;
typedef ConstNot<PlainScalarRejection> PlainScalar;

typedef ConstCharSet<'?', ',', '[', ']', '{', '}', '#', '&', '*', '!', '|', '>',
                     '\'', '"', '%', '@', 0x60>
    PlainScalarFlowTerminators;
typedef ConstCharSet<'-', ':'> PlainScalarFlowIndicators;
typedef ConstOr<
    BlankOrBreak,
    ConstOr<PlainScalarFlowTerminators,
            ConstSeq<PlainScalarFlowIndicators, ConstOr<Blank, Empty>>>>
    PlainScalarFlowRejection;
typedef ConstNot<PlainScalarFlowRejection> PlainScalarInFlow;

typedef ConstSeq<ConstByte<':'>, DocumentMarkerSuffix> EndScalar;
typedef ConstCharSet<',', '?', '[', ']', '{', '}'> FlowScalarTerminators;
typedef ConstSeq<ConstByte<':'>,
                 ConstOr<ConstOr<BlankOrBreak, Empty>, FlowValueTerminators>>
    EndScalarInFlowPrefix;
typedef ConstOr<EndScalarInFlowPrefix, FlowScalarTerminators> EndScalarInFlow;
typedef ConstSeq<BlankOrBreak, Comment> CommentAfterBreak;
typedef ConstOr<EndScalarInFlow, CommentAfterBreak> ScanScalarEndInFlow;
typedef ConstOr<EndScalar, CommentAfterBreak> ScanScalarEnd;
typedef ConstSeq<ConstByte<'\''>, ConstByte<'\''>> EscSingleQuote;
typedef ConstSeq<ConstByte<'\\'>, Break> EscBreak;
typedef ConstAnd<ConstByte<'\''>, ConstNot<EscSingleQuote>> SingleQuoteEnd;
typedef ConstByte<'"'> DoubleQuoteEnd;
typedef ConstCharSet<'+', '-'> ChompIndicator;
typedef ConstOr<
    ConstSeq<ChompIndicator, Digit>,
    ConstOr<ConstSeq<Digit, ChompIndicator>, ConstOr<ChompIndicator, Digit>>>
    Chomp;
typedef ConstOr<Tab, Ampersand> DisallowedWhitespace;
typedef ConstOr<Break, DisallowedWhitespace> DisallowedBreak;
typedef ConstOr<Utf8ByteOrderMark, DisallowedBreak> DisallowedEncoding;
typedef ConstOr<NotPrintable, DisallowedEncoding> DisallowedCharacters;
typedef ConstOr<CommentAfterBreak, DisallowedCharacters> DisallowedAfterComment;
typedef ConstOr<EndScalarInFlow, DisallowedAfterComment> DisallowedFlow;
typedef ConstOr<EndScalar, DisallowedAfterComment> DisallowedBlock;
}  // namespace Patterns

template <typename Pattern>
inline const ConstRegEx& Get() {
  static constexpr ConstRegEx expression = MakeConstRegEx<Pattern>();
  return expression;
}

inline const ConstRegEx& Empty() { return Get<Patterns::Empty>(); }
inline const ConstRegEx& Space() { return Get<Patterns::Space>(); }
inline const ConstRegEx& Tab() { return Get<Patterns::Tab>(); }
inline const ConstRegEx& Blank() { return Get<Patterns::Blank>(); }
inline const ConstRegEx& Break() { return Get<Patterns::Break>(); }
inline const ConstRegEx& BlankOrBreak() {
  return Get<Patterns::BlankOrBreak>();
}
inline const ConstRegEx& Digit() { return Get<Patterns::Digit>(); }
inline const ConstRegEx& Alpha() { return Get<Patterns::Alpha>(); }
inline const ConstRegEx& AlphaNumeric() {
  return Get<Patterns::AlphaNumeric>();
}
inline const ConstRegEx& Word() { return Get<Patterns::Word>(); }
inline const ConstRegEx& Hex() { return Get<Patterns::Hex>(); }
inline const ConstRegEx& NotPrintable() {
  return Get<Patterns::NotPrintable>();
}
inline const ConstRegEx& Utf8_ByteOrderMark() {
  return Get<Patterns::Utf8ByteOrderMark>();
}
inline const ConstRegEx& DocStart() { return Get<Patterns::DocumentStart>(); }
inline const ConstRegEx& DocEnd() { return Get<Patterns::DocumentEnd>(); }
inline const ConstRegEx& DocIndicator() {
  return Get<Patterns::DocumentIndicator>();
}
inline const ConstRegEx& BlockEntry() { return Get<Patterns::BlockEntry>(); }
inline const ConstRegEx& Key() { return Get<Patterns::Key>(); }
inline const ConstRegEx& KeyInFlow() { return Get<Patterns::KeyInFlow>(); }
inline const ConstRegEx& Value() { return Get<Patterns::Value>(); }
inline const ConstRegEx& ValueInFlow() { return Get<Patterns::ValueInFlow>(); }
inline const ConstRegEx& ValueInJSONFlow() {
  return Get<Patterns::ValueInJSONFlow>();
}
inline const ConstRegEx& Ampersand() { return Get<Patterns::Ampersand>(); }
inline const ConstRegEx& Comment() { return Get<Patterns::Comment>(); }
inline const ConstRegEx& Anchor() { return Get<Patterns::Anchor>(); }
inline const ConstRegEx& AnchorEnd() { return Get<Patterns::AnchorEnd>(); }
inline const ConstRegEx& URI() { return Get<Patterns::Uri>(); }
inline const ConstRegEx& Tag() { return Get<Patterns::Tag>(); }
inline const ConstRegEx& PlainScalar() { return Get<Patterns::PlainScalar>(); }
inline const ConstRegEx& PlainScalarInFlow() {
  return Get<Patterns::PlainScalarInFlow>();
}
inline const ConstRegEx& EndScalar() { return Get<Patterns::EndScalar>(); }
inline const ConstRegEx& EndScalarInFlow() {
  return Get<Patterns::EndScalarInFlow>();
}
inline const ConstRegEx& ScanScalarEndInFlow() {
  return Get<Patterns::ScanScalarEndInFlow>();
}
inline const ConstRegEx& ScanScalarEnd() {
  return Get<Patterns::ScanScalarEnd>();
}
inline const ConstRegEx& EscSingleQuote() {
  return Get<Patterns::EscSingleQuote>();
}
inline const ConstRegEx& EscBreak() { return Get<Patterns::EscBreak>(); }
inline const ConstRegEx& SingleQuoteEnd() {
  return Get<Patterns::SingleQuoteEnd>();
}
inline const ConstRegEx& DoubleQuoteEnd() {
  return Get<Patterns::DoubleQuoteEnd>();
}
inline const ConstRegEx& ChompIndicator() {
  return Get<Patterns::ChompIndicator>();
}
inline const ConstRegEx& Chomp() { return Get<Patterns::Chomp>(); }
inline const ConstRegEx& DisallowedFlow() {
  return Get<Patterns::DisallowedFlow>();
}
inline const ConstRegEx& DisallowedBlock() {
  return Get<Patterns::DisallowedBlock>();
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
