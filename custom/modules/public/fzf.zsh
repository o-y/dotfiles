
##
## FZF Configuration
## Derives from the link at the bottom of this file
## This theme matches the Bearded Arc theme which is used in
## ghostty, see packages/ghostty/themes/dark_master
## --
## bg          = #1e2432  [bearded-arc-bg]
## fg          = #eaeaea  [bearded-arc-fg]
## accent      = #323847 
## bg_dark     = darken(bg, 10%)      = #1b202d
## header_text = lighten(accent, 20%) = #525c75
## search_text = lighten(accent, 40%) = #76829f
## --

export FZF_DEFAULT_OPTS='
  --color=fg:-1,fg+:#eaeaea,bg:-1,bg+:#1b202d
  --color=hl:#f3f59d,hl+:#ca9ee6,info:#525c75,marker:#caaafe
  --color=prompt:#ff6e6f,spinner:#525c75,pointer:#ca9ee6,header:#525c75
  --color=gutter:#1e2432,border:#323847,preview-border:#323847,label:#323847
  --color=query:#eaeaea
  --preview-window="border-rounded" 
  --padding="1"
  --prompt="> " 
  --pointer="◆ "
  --border-label-pos="0"
  --no-separator
  --no-scrollbar'


## By default a border is not shown, but this can be enabled by calling fzf with this option:
## --border-label-pos="0" --border="rounded" --border-label="<optional border label>"

## FZF Theme generator playground permalink:
## https://vitormv.github.io/fzf-themes#eyJib3JkZXJTdHlsZSI6InJvdW5kZWQiLCJib3JkZXJMYWJlbCI6Ikhpc3RvcnkgTG9va3VwIiwiYm9yZGVyTGFiZWxQb3NpdGlvbiI6MCwicHJldmlld0JvcmRlclN0eWxlIjoicm91bmRlZCIsInBhZGRpbmciOiIxIiwibWFyZ2luIjoiIiwicHJvbXB0IjoiPiAiLCJtYXJrZXIiOiIiLCJwb2ludGVyIjoi4peGICIsInNlcGFyYXRvciI6IiIsInNjcm9sbGJhciI6IiIsImxheW91dCI6ImRlZmF1bHQiLCJpbmZvIjoiZGVmYXVsdCIsImNvbG9ycyI6ImZnOiNlYWVhZWEsZmcrOiNlYWVhZWEsYmc6IzFlMjQzMixiZys6IzFiMjAyZCxobDojZjNmNTlkLGhsKzojY2E5ZWU2LGluZm86IzUyNWM3NSxtYXJrZXI6IzVhYWE1OCxwcm9tcHQ6I2ZmNmU2ZixzcGlubmVyOiM1MjVjNzUscG9pbnRlcjojY2E5ZWU2LGhlYWRlcjojNTI1Yzc1LGd1dHRlcjojMWUyNDMyLGJvcmRlcjojMzIzODQ3LHByZXZpZXctYm9yZGVyOiMzMjM4NDcsbGFiZWw6IzMyMzg0NyxxdWVyeTojZWFlYWVhIn0=
