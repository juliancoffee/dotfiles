if exists("b:current_syntax")
  finish
endif

syntax match fluentComment /^\s*#.*/
syntax match fluentAttribute /^\s*\.\<[A-Za-z][A-Za-z0-9_-]*\>/
syntax match fluentVariable /\$[A-Za-z][A-Za-z0-9_-]*/
syntax match fluentVariant /\*\?\[\s*[A-Za-z0-9_-]\+\s*\]/
syntax match fluentFunction /\<[A-Z][A-Z0-9_-]*\ze(/
syntax match fluentOperator /->\|=\|{\|}/

highlight def link fluentComment Comment
highlight def link fluentAttribute Keyword
highlight def link fluentVariable Identifier
highlight def link fluentVariant Tag
highlight def link fluentFunction Function
highlight def link fluentOperator Operator

let b:current_syntax = "fluent"
