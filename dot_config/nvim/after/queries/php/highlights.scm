;; extends
(use_declaration (qualified_name) @type)
; override @constant capture (fix DB highlighted as const)
(scoped_call_expression scope: (name) @type)
(namespace_use_declaration
  (namespace_use_clause
    (qualified_name (name) @type)))
(namespace_use_declaration
  (namespace_use_clause
    (qualified_name
      (namespace_name_as_prefix
        (namespace_name (name) @type)))))
