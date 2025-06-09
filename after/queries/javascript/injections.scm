;extends

((variable_declarator
   name: (identifier) @_id
   value: (template_string (string_fragment) @injection.content))
   (#match? @_id "Query")
   (#set! injection.language "sql")
 )

((variable_declarator
   name: (identifier) @_id
   value: (string (string_fragment) @injection.content))
   (#match? @_id "Query")
   (#set! injection.language "sql")
 )

