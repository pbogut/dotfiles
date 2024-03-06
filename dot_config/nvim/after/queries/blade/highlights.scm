(directive) @keyword
(directive_start) @keyword
(directive_end) @keyword
(comment) @comment
;((parameter) @string (#set! "priority" 110))
;((php_only) @include (#set! "priority" 110))
((bracket_start) @function (#set! "priority" 120))
((bracket_end) @function (#set! "priority" 120))
(keyword) @function
