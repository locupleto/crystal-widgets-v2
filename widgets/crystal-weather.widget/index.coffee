# crystal-weather.widget by locupleto
#
# https://github.com/locupleto/crystal-widgets-v2
#
# Current weather conditions from OpenWeatherMap. The panel is entirely
# invisible unless OPENWEATHERMAP_API_KEY is configured in
# crystal_common.sh and at least one fetch has succeeded (fail-safe).

command: "crystal-weather.widget/widget_runner.sh"

# Frequency of data refresh. The runner only calls the OpenWeatherMap
# API every 10 minutes; in between it re-reads the local cache, so this
# can be much faster than the API interval.
refreshFrequency: 60000

# Styling for the widget. NOTE: the outer widget style carries position
# only -- all visible chrome sits on .container so the entire panel can
# disappear when no API key / no data is available (fail-safe).
style: """
  top: 229px
  left: 10px
  color: #fff
  font-family: Helvetica Neue

  .container
    display: none
    width: 370px
    padding: 10px
    background: rgba(#FFF, .1)
    border-radius: 5px

  .content
    display: flex
    align-items: center
    gap: 12px
    height: 60px

  .weather-icon
    flex: 0 0 60px
    width: 60px
    height: 60px

  .weather-icon svg
    display: block
    width: 100%
    height: 100%

  .weather-icon.tinted svg,
  .weather-icon.tinted svg path
    fill: rgba(#fff, .92)

  .temp
    font-size: 30px
    font-weight: 200
    line-height: 32px
    text-shadow: 0 1px 0px rgba(#000, .7)

  .condition
    font-size: 11px
    font-weight: 300
    color: rgba(#fff, .9)

  .secondary
    margin-left: auto
    text-align: right
    font-size: 11px
    font-weight: 300
    line-height: 15px
    color: rgba(#fff, .75)

  .city
    font-size: 10px
    text-transform: uppercase
    font-weight: bold
    color: #fff

  .stale-hint
    font-size: 9px
    font-weight: 300
    color: rgba(#fff, .45)
    margin-right: 4px
"""

# Rendering the widget layout (static skeleton; update() fills it in)
render: ->
  """
  <div class="container">
    <div class="content">
      <div class="weather-icon"></div>
      <div class="primary">
        <div class="temp"></div>
        <div class="condition"></div>
      </div>
      <div class="secondary">
        <div><span class="stale-hint"></span><span class="city"></span></div>
        <div class="feels"></div>
        <div class="extras"></div>
      </div>
    </div>
  </div>
  """

# Updating the widget with new data
update: (output, domEl) ->
  container = $(domEl).find('.container')

  # FAIL-SAFE: empty output means no key / no cache -> hide everything
  if not output? or output.trim() == ""
    container.hide()
    return

  try
    data = JSON.parse(output)
  catch error
    container.hide()
    return

  if data.status != "ok"
    container.hide()
    return

  # Inject the SVG inline so SMIL animations run and the Erik Flowers
  # glyphs can be tinted via CSS. Only one icon is in the DOM at a time,
  # so gradient ids inside meteocons files cannot collide.
  iconEl = $(domEl).find('.weather-icon')
  iconEl.html(data.icon_svg)
  iconEl.toggleClass('tinted', data.icon_set == 'weather-icons')

  $(domEl).find('.temp').text(data.temp)
  $(domEl).find('.condition').text(data.condition)
  $(domEl).find('.city').text(data.city)
  $(domEl).find('.feels').text("Feels like #{data.feels}")
  $(domEl).find('.extras').text("#{data.humidity} · #{data.wind}")
  $(domEl).find('.stale-hint').text(if data.stale then "⟳ #{data.age_min}m" else "")

  container.css('display', 'block')
