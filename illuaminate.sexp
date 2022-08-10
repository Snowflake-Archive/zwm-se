; -*- mode: Lisp;-*-

(sources
  /bin/
  /lib/
  /docs-src/
)

(doc
  (destination docs)
  (index README.md)

  (site
    (title "zwm SE")
    (styles docs-src/styles.css)
  )

  (module-kinds
    (core Core)
    (utils Utilities)
    (registry Registry)
    (ui UI)
    (tables Tables)
    (deprecated Deprecated)
  )

  (library-path
    /lib/
    /docs-src/
  )
)

(at /
  (linters
    -doc:unresolved-reference
  )
  (lint
    (globals
      :max
      _CC_DEFAULT_SETTINGS
      _CC_DISABLE_LUA51_FEATURES
      sleep 
      write 
      printError 
      read 
      rs 
      colors
      colours
      commands
      disk
      fs
      gps
      help
      http
      io
      keys
      multishell
      os 
      paintutils
      parallel
      peripheral
      pocket
      rednet
      redstone
      settings 
      shell
      term
      textutils
      turtle
      vector
      window
      _HOST
    )
  )
)