# crystal-theme.widget by locupleto
#
# https://github.com/locupleto/crystal-widgets
#
# Publishes The Gallery's crystal colour variables into the shared Übersicht
# document so every crystal widget can pick them up with var(--crystal-*)
# and fall back to its own shipped colour when the Gallery is absent or its
# widget colouring is switched off (`gallery widgets native`).
#
# ~/.config/gallery/state/crystal.css is written by the-gallery's
# tools/render-theme.py; empty or missing means "no override". This widget
# draws nothing itself.

command: "cat \"$HOME/.config/gallery/state/crystal.css\" 2>/dev/null || true"

refreshFrequency: 2000

style: """
display: none
"""

render: (output) ->
  "<style class='crystal-theme'></style>"

update: (output, domEl) ->
  $(domEl).find('style.crystal-theme').text(output)
