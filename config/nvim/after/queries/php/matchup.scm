(foreach_statement
  ("foreach" @open.foreach)
  ("endforeach" @close.foreach)) @scope.foreach
; (break_statement) @mid.foreach.1
; (continue_statement) @mid.foreach.1

(for_statement
  ("for" @open.for)
  ("endfor" @close.for)) @scope.for
; (break_statement) @mid.for.1
; (continue_statement) @mid.for.1

(if_statement
  ("if" @open.if)
  (else_clause "else" @mid.if.1)?
  ("endif" @close.if)) @scope.if
