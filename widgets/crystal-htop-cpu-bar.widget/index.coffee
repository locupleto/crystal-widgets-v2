# crystal-htop-cpu-bar.widget by locupleto
#
# https://github.com/locupleto/crystal-widgets

command: "crystal-htop-cpu-bar.widget/widget_runner.sh"

# Frequency of data refresh
refreshFrequency: 1000

# Styling for the widget
style: """
  // General widget styling
  top: 318px;
  left: 10px;
  color: #fff;
  font-family: Helvetica Neue;
  background: rgba(#FFF, .1);
  padding: 10px;
  border-radius: 5px;
  width: 370px;
  position: relative;

  .widget-title {
    font-size: 10px;
    font-weight: bold;
    margin-bottom: 8px;
  }

  .cpu-bar-container {
    display: flex;
    align-items: flex-end;
    height: 40px; // Max height for 100% CPU usage
    width: 100%;
    gap: 2px;
    border: 1px solid rgba(255, 255, 255, 0.15); // Dim white outline only for the histogram
  }

  .cpu-bar {
    background: rgba(#fc0, .5);
    width: calc(100% / 20); // Adjust according to the number of CPUs
    transition: height .2s ease-in-out;
    border: 1px solid rgba(255, 255, 255, 0.3); // Light white border for individual bars
  }
"""

# Rendering the widget layout
render: ->
  """
  <div class="container">
    <div class="widget-title">CPU usage</div>
    <div class="cpu-bar-container"></div>
  </div>
  """

# Updating the widget with new data
update: (output, domEl) ->
  if not output? or output.trim() == ""
    return

  segments = output.trim().split(";")
  cpuUsages = segments.slice(0, -2)  # Exclude the last two elements (colors)
  cpuBarColor = segments[segments.length - 2]  # Second last element is the fill color
  cpuBarBorderColor = segments[segments.length - 1]  # Last element is the border color

  cpuBarContainer = $(domEl).find(".cpu-bar-container")
  cpuBarContainer.empty()

  numCPUs = cpuUsages.length
  barWidth = (100 / numCPUs).toFixed(2) + "%"  # Calculate the width percentage for each CPU bar

  for usage in cpuUsages
    percentHeight = parseFloat(usage.trim()) * 40 / 100 # Convert percentage to height
    # Set the width dynamically based on the number of CPUs
    cpuBarContainer.append "<div class='cpu-bar' style='height: #{percentHeight}px; width: #{barWidth}; background-color: #{cpuBarColor}; border-color: #{cpuBarBorderColor}'></div>"
