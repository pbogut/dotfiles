; inherits: html_tags

(php_statement
  (directive_start) @open.php
  (directive_end) @close.php) @scope.php

(loop
  (directive_start) @open.foreach
  ((loop_operator) @mid.foreach.1)?
  (directive_end) @close.foreach) @scope.foreach

(conditional
  (directive_start) @open.if
  ((conditional_keyword) @mid.if.1)?
  (directive_end) @close.if) @scope.if

(switch
  (directive_start) @open.switch
  ((directive) @mid.switch.1)?
  (directive_end) @close.switch) @scope.switch

(section
 (directive_start) @open.section
 (directive_end) @close.section) @scope.section

(stack
 (directive_start) @open.stack
 (directive_end) @close.stack) @scope.stack

(verbatim
  (directive_start) @open.verbatim
  (directive_end) @close.verbatim) @scope.verbatim

(once
  (directive_start) @open.once
  (directive_end) @close.once) @scope.once
