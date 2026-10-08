---
title: foresight_tokens
---

# foresight_tokens

> foresight_tokens, lexer of the gnuplot-like command language.

 A line is split into statements at `;` and cut at `#` (both outside quotes); a statement into tokens: words,
 quoted strings (single quotes literal, double quotes with `\t` for a tab and `\` taking the next character literally,
 so `\"` and `\\`, as gnuplot), commas and bracketed ranges `[a:b]`. Each token remembers where it lies in the
 statement, so that a plot item can be quoted as written. Inside parentheses a word goes on across blanks and commas:
 `($2 * 1e3)` and `atan2($2, $1)` are single words; quotes inside a word keep their content, blanks included, and a
 quoted string followed by `:` starts a word: `1:"the res"` and `"it":"res"` are `using` specifications.

**Source**: `src/lib/foresight_tokens.F90`

## Contents

- [token_object](#token-object)
- [split_statements](#split-statements)
- [tokenize](#tokenize)

## Variables

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `TOKEN_WORD` | integer(kind=I4P) | parameter | Bare word: keyword, number, column spec. |
| `TOKEN_STRING` | integer(kind=I4P) | parameter | Quoted string, quotes removed. |
| `TOKEN_COMMA` | integer(kind=I4P) | parameter | Comma. |
| `TOKEN_RANGE` | integer(kind=I4P) | parameter | Bracketed range, brackets removed. |

## Derived Types

### token_object

Token.

#### Components

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `kind` | integer(kind=I4P) |  | Token kind. |
| `text` | character(len=:) | allocatable | Token text. |
| `quote` | character(len=1) |  | Quote of a string token, blank for others. |
| `first` | integer(kind=I4P) |  | First character in the statement, quotes or brackets included. |
| `last` | integer(kind=I4P) |  | Last character in the statement. |

## Subroutines

### split_statements

Split `line` at `;` outside quotes, dropping the `#` comment; blank statements are skipped.

```fortran
subroutine split_statements(line, statements)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `line` | character(len=*) | in |  | Source line. |
| `statements` | type([token_object](/api/src/lib/foresight_tokens#token-object)) | out | allocatable | Statements (kind word). |

**Call graph**

```mermaid
flowchart TD
  split_statements["split_statements"] --> add["add"]
  style split_statements fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### tokenize

Split `statement` into tokens.

**Attributes**: pure

```fortran
subroutine tokenize(statement, tokens, iostat, iomsg)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `statement` | character(len=*) | in |  | Statement. |
| `tokens` | type([token_object](/api/src/lib/foresight_tokens#token-object)) | out | allocatable | Tokens. |
| `iostat` | integer(kind=I4P) | out |  | 0, or 1 on a lexical error. |
| `iomsg` | character(len=:) | out | allocatable | Error message. |

**Call graph**

```mermaid
flowchart TD
  execute["execute"] --> tokenize["tokenize"]
  tokenize["tokenize"] --> closing_quote["closing_quote"]
  tokenize["tokenize"] --> count_parentheses["count_parentheses"]
  style tokenize fill:#3e63dd,stroke:#99b,stroke-width:2px
```
