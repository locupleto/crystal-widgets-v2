# crystal-htop-swap-bar.widget by locupleto
#
# https://github.com/locupleto/crystal-widgets

command: "crystal-htop-swap-bar.widget/widget_runner.sh"

# Frequency of data refresh
refreshFrequency: 2000

# Styling for the widget
style: """
  // Change bar height
  bar-height = 6px

  // Align contents left
  widget-align = left

  // Position of the widget
  top: 672px; // Adjusted to original swap widget position
  left: 10px

  // Text and background styling
  color: #fff
  font-family: Helvetica Neue
  background: rgba(#FFF, .1)
  padding: 10px 10px 15px
  border-radius: 5px

  .container {
    width: 370px
    text-align: widget-align
    position: relative
    clear: both
  }

  .widget-title {
    text-align: widget-align
    font-size: 10px
    text-transform: uppercase
    font-weight: bold
  }

  .stats-container {
    margin-bottom: 5px
    border-collapse: collapse
  }

  td {
    font-size: 12px
    font-weight: 300
    color: rgba(#fff, .9)
    text-shadow: 0 1px 0px rgba(#000, .7)
    text-align: widget-align
    width: 50px
    padding: 2px 0
  }

  .right-align {
    text-align: right
  }

  .bar-container {
    width: 100%
    height: bar-height
    border-radius: bar-height
    float: widget-align
    clear: both
    background: rgba(#fff, .2)
    position: absolute
    margin-bottom: 5px
  }

  .bar {
    height: bar-height
    float: widget-align
    transition: width .2s ease-in-out
  }

  .bar-available {
    background: none
  }

  .bar-used {
    background: rgba(0, 255, 127, 0.5)  // Dynamically set
  }
"""

# Rendering the widget layout
render: ->
  """
  <div class="container">
    <div class="widget-title">Swap</div>
    <table class="stats-container" width="100%">
      <tr>
        <td class="stat"><span class="used"></span></td>
        <td class="stat right-align"><span class="available"></span></td>
      </tr>
      <tr>
        <td class="label">Used</td>
        <td class="label right-align">Available</td>
      </tr>
    </table>
    <div class="bar-container">
      <div class="bar bar-used"></div>
      <div class="bar bar-available"></div>
    </div>
  </div>
  """ 

# Updating the widget with new data
update: (output, domEl) ->
  # Using regex to split by spaces outside of parentheses
  entries = output.trim().match(/(?:[^\s()]+|\([^)]*\))+/g)
  
  if not entries or entries.length < 6
    return  # Silently abort if data format is incorrect or incomplete

  [rawAvailable, humanAvailable, rawUsed, humanUsed, fillColor, borderColor] = entries

  # Validate numeric data to ensure they are actual numbers
  if isNaN(parseFloat(rawAvailable)) or isNaN(parseFloat(rawUsed))
    return  # Abort if swap data is not numeric

  # Validate color format (assuming RGBA format is expected)
  rgbaRegex = /^rgba\((\d{1,3},\s?){3}[\d\.]+\)$/
  if not rgbaRegex.test(fillColor) or not rgbaRegex.test(borderColor)
    return  # Abort if color format is incorrect

  # Calculate percentages and update UI
  maxMemory = parseFloat(rawAvailable) + parseFloat(rawUsed)
  updateSwapStat = (sel, rawValue, humanValue, color) ->
    percent = "0%"
    if maxMemory > 0
      percent = (parseFloat(rawValue) / maxMemory * 100).toFixed(2) + "%"
    $(domEl).find(".#{sel}").text(humanValue)  
    $(domEl).find(".bar-#{sel}").css "width", percent
    $(domEl).find(".bar-#{sel}").css "background-color", color  

  # Update UI elements even if total memory is zero
  updateSwapStat 'used', rawUsed, humanUsed, fillColor
  updateSwapStat 'available', rawAvailable, humanAvailable, "rgba(255, 255, 255, 0)"
