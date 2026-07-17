# crystal-htop-load.widget by locupleto
#
# https://github.com/locupleto/crystal-widgets

command: "crystal-htop-load.widget/widget_runner.sh"

# Frequency of data refresh
refreshFrequency: 2000

# Styling for the widget
style: """
  // General widget styling
  top: 408px;
  left: 10px;
  color: #fff;
  font-family: Helvetica Neue;
  background: rgba(#FFF, .1);
  padding: 10px 10px 2px;
  border-radius: 5px;
  width: 370px;

  .widget-title {
    font-size: 10px;
    font-weight: bold;
    margin-bottom: 18px;
  }

  .stat-row {
    font-size: 11px;
    font-weight: 300;
    color: rgba(#fff, .9);
    text-shadow: 0 1px 0px rgba(#000, .7);
    margin-bottom: 4px; // Spacing between rows
    display: flex; // Use flexbox for layout
    justify-content: space-between; // Space out left and right data
  }

  .left-data, .right-data {
    flex: 1; // Flex-grow to fill available space
    padding-right: 0px; // Add some padding for spacing
  }

  .right-data {
    text-align: right;
  }
"""

# Rendering the widget layout
render: ->
  """
  <div class="container">
    <div class="widget-title">CPU load</div>
    <div class="stat-row">
      <span class="left-data">Tasks:</span>
      <span class="right-data">Loading...</span>
    </div>
    <div class="stat-row">
      <span class="left-data">Load average:</span>
      <span class="right-data">Loading...</span>
    </div>
    <div class="stat-row">
      <span class="left-data"></span>
      <span class="right-data">Loading...</span>
    </div>
  </div>
  """

# Updating the widget with new data
update: (output, domEl) ->
  [load1, load2, load3, tasks, threads, uptime] = output.trim().split(";")

  # Update the widget with the new values
  $(domEl).find(".stat-row").eq(0).find(".left-data").text "Tasks: #{tasks}"
  $(domEl).find(".stat-row").eq(0).find(".right-data").text "Threads: #{threads}"
  $(domEl).find(".stat-row").eq(1).find(".left-data").text "Load average: #{load1} #{load2} #{load3}"
  $(domEl).find(".stat-row").eq(1).find(".right-data").text "System uptime: #{uptime}"
  $(domEl).find(".stat-row").eq(2).find(".right-data").text ""
