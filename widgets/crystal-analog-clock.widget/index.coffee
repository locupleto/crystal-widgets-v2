# crystal-analog-clock.widget
#
# https://github.com/locupleto/crystal-widgets
#
# Based on simple-analog-clock by Viktor Strate
# which in turn is based on SmoothAnalogClock by N00bySumairu
# https://github.com/N00bySumairu/SmoothAnalogClock.widget

options =
  pos:
    x: "left: 15px"
    y: "top: 27px"
  size: 180                           # width of the clock in px
  scale: 1                            # for retina displays set to 2
  fontSize: 24                        # in px
  secPtr:
    color: "rgb(209,97,143)"          # css color string
    width: 1                          # in px
    length: 72                        # in px
  minPtr:
    color: "rgb(40,40,40)"            # css color string
    width: 1                          # in px
    length: 68                        # in px
  hrPtr:
    color: "rgb(40,40,40)"            # css color string
    width: 1                          # in px
    length: 44                        # in px
  markerOffset: 4                     # offset from the border of the clock in px
  majorMarker:
    width: 1                          # in px
    length: 24                        # in px
  minorMarker:
    width: 1                          # in px
    length: 8                         # in px
  intervalLength: 30  # interval between the transition triggers in seconds
  backgroundBlur: false

refreshFrequency: "30s" # change this as well when changing the intervalLength

# End of styling options

render: (_) -> """
<div class="clock">
  <div class="markers"></div>
  <div class="secPtr"></div>
  <div class="hrPtr"></div>
  <div class="minPtr"></div>
</div>
"""

afterRender: (domEl) ->
  # Initialize the markers (I just wanted to keep the render function small and tidy)
  markers = $(domEl).find('.markers')
  for i in [0...12]
    for j in [0...5]
      id = ""
      cls = ""
      if j is 0
        id = i+1
        cls = "major"
      else
        id = (i+1)+"_"+j
        cls = "minor"
      rotation = -60 + 6 * (i * 5 + j)
      markers.append('<div id="'+id+'" class="'+cls+'" style="transform: rotate('+rotation+'deg);"></div>')
  # Prevent blocking of the clock for the refresh duration after widget refresh
  setTimeout(@refresh)

update: (_, domEl) ->
  # Use the time elapsed (in ms) since 0:00 of the current day
  time = Date.now() - (new Date()).setHours(0,0,0,0)

  div = $(domEl)
  pointers = div.find('.secPtr, .minPtr, .hrPtr')

  # Set the rotation of the pointers to what they should be at the current time
  # (without transition, to prevent the pointer from rotating backwards around the beginning of the day)
  # Disable transition
  pointers.removeClass('pointer')
  div.find('.secPtr').css('transform', 'rotate('+(-90+time/60000*360)+'deg)')
  div.find('.minPtr').css('transform', 'rotate('+(-90+time/3600000*360)+'deg)')
  div.find('.hrPtr').css('transform', 'rotate('+(-90+time/43200000*360)+'deg)')
  # Trigger a reflow, flushing the CSS changes (see http://stackoverflow.com/questions/11131875/what-is-the-cleanest-way-to-disable-css-transition-effects-temporarily)
  div[0].offsetHeight
  # Enable transition again
  pointers.addClass('pointer')

  # Trigger transition to the rotation of the pointers in 10s
  time += options.intervalLength * 1000
  div.find('.secPtr').css('transform', 'rotate('+(-90+time/60000*360)+'deg)')
  div.find('.minPtr').css('transform', 'rotate('+(-90+time/3600000*360)+'deg)')
  div.find('.hrPtr').css('transform', 'rotate('+(-90+time/43200000*360)+'deg)')

style: """
#{options.pos.x}
#{options.pos.y}

.clock {
  width: #{options.size * options.scale}px;
  height: #{options.size * options.scale}px;
  border-radius: 50%;
  background-color: rgba(255, 255, 255, 0.1); /* Slightly opaque white background */
  box-shadow: 0 0 8px rgba(0,0,0,0.1);
  overflow: hidden;
}

.pointer
  transition: transform #{options.intervalLength}s linear

.secPtr
  position: absolute
  top: #{options.size * options.scale / 2 - options.secPtr.width * options.scale / 2}px
  left: #{options.size * options.scale / 2 - options.secPtr.width / 2 * options.scale}px
  width: #{options.secPtr.length * options.scale}px
  height: #{options.secPtr.width * options.scale}px
  background-color: #{options.secPtr.color}
  border-left: 0px transparent solid
  border-top-left-radius: #{options.secPtr.width / 2 * options.scale}px
  border-bottom-left-radius: #{options.secPtr.width / 2 * options.scale}px
  transform-origin: #{options.secPtr.width / 2 * options.scale}px 50%
  transform: rotate(-90deg)

.minPtr
  position: absolute
  top: #{options.size * options.scale / 2 - options.minPtr.width * options.scale / 2}px
  left: #{options.size * options.scale / 2 - options.minPtr.width / 2 * options.scale}px
  width: #{options.minPtr.length * options.scale}px
  height: #{options.minPtr.width * options.scale}px
  background-color: rgba(255,255,255,1.0);//#{options.minPtr.color}
  border-left: 0px transparent solid
  border-top-left-radius: #{options.minPtr.width / 2 * options.scale}px
  border-bottom-left-radius: #{options.minPtr.width / 2 * options.scale}px
  transform-origin: #{options.minPtr.width / 2 * options.scale}px 50%
  transform: rotate(-90deg)

.hrPtr
  position: absolute
  top: #{options.size * options.scale / 2 - options.hrPtr.width * options.scale / 2}px
  left: #{options.size * options.scale / 2 - options.hrPtr.width / 2 * options.scale}px
  width: #{options.hrPtr.length * options.scale}px
  height: #{options.hrPtr.width * options.scale}px
  background-color: rgba(255,255,255,1.0); //#{options.hrPtr.color}
  border-left: 0px transparent solid
  border-top-left-radius: #{options.hrPtr.width / 2 * options.scale}px
  border-bottom-left-radius: #{options.hrPtr.width / 2 * options.scale}px
  transform-origin: #{options.minPtr.width / 2 * options.scale}px 50%
  transform: rotate(-90deg)

.markers > .major
  position: absolute
  top: #{options.size * options.scale / 2 - options.majorMarker.width * options.scale / 2}px
  left: #{options.size * options.scale / 2 - (-options.size / 2 + options.majorMarker.length + options.markerOffset) * options.scale}px
  width: #{options.majorMarker.length * options.scale}px
  height: #{options.majorMarker.width * options.scale}px
  background-color: rgba(255,255,255,1.0)
  transform-origin: #{(-options.size / 2 + options.majorMarker.length + options.markerOffset) * options.scale}px 50%

.markers > .minor
  position: absolute
  top: #{options.size * options.scale / 2 - options.minorMarker.width * options.scale / 2}px
  left: #{options.size * options.scale / 2 - (-options.size / 2 + options.minorMarker.length + options.markerOffset) * options.scale}px
  width: #{options.minorMarker.length * options.scale}px
  height: #{options.minorMarker.width * options.scale}px
  background-color: rgba(255,255,255,0.2)
  transform-origin: #{(-options.size / 2 + options.minorMarker.length + options.markerOffset) * options.scale}px 50%
"""

