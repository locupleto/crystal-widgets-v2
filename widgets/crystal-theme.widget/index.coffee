# crystal-theme.widget by locupleto
#
# https://github.com/locupleto/crystal-widgets
#
# Publishes an optional external colour feed into the shared Übersicht
# document so every crystal widget can pick it up with var(--crystal-*)
# and fall back to its own shipped colour when the feed is absent.
#
# The feed is a CSS file defining --crystal-* custom properties; empty or
# missing means "no override". This widget draws nothing itself.

command: "cat \"$HOME/.config/gallery/state/crystal.css\" 2>/dev/null || true"

refreshFrequency: 2000

style: """
display: none
"""

render: (output) ->
  "<style class='crystal-theme'></style>"

update: (output, domEl) ->
  $(domEl).find('style.crystal-theme').text(output)
