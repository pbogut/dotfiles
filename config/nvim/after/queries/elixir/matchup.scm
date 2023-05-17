(call
  (do_block ("do") @open.do))
(call
  (identifier) @open.do
  (do_block
    (else_block "else" @mid.do.1)?
    (stab_clause (arguments) @mid.do.1)?
    "end" @close.do)) @scope.do

; (call (identifier) @open.if
;       (#eq? @open.if "if")
;       (do_block (else_block "else" @mid.if.1)? "end" @close.if)) @scope.if

; (call (identifier) @open.def
;       (#eq? @open.def "def")
;       (do_block "end" @close.def)) @scope.def

; (call (identifier) @open.def
;       (#eq? @open.def "defp")
;       (do_block "end" @close.def)) @scope.def

; (call (identifier) @open.do (do_block))
; (call (do_block ("do") @open.do))
; ("end") @close.do


