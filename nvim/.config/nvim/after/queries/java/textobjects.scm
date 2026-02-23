; extends
(class_declaration) @class.outer
(interface_declaration) @class.outer
(record_declaration) @class.outer

(class_body) @class.inner
(interface_body) @class.inner
(class_body) @class.inner  ; use class_body again for record body
