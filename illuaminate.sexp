; -*- mode: Lisp;-*-

(sources
  /lib/ui/
  /lib/
)

(doc
  (destination docs)
  (index README.md)

  (site
    (title "zwm SE")
  )

  (module-kinds
    (core Core)
    (ui UI)
  )

  (library-path
    /lib/ui/
    /lib/
  )
)