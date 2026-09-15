# crystal-system-profiler.widget by locupleto
#
# https://github.com/locupleto/crystal-widgets

# Übersicht runs this from the ROOT of the widgets folder, so a fixed
# relative path breaks the moment the suite sits one folder deeper (the
# usual result of unzipping the bundle). Locate our own script instead,
# and run it through bash so a lost executable bit cannot break it either.
command: "f=$(find . -maxdepth 4 -type f -path \"*/crystal-system-profiler.widget/widget_script.sh\" -print -quit 2>/dev/null); [ -n \"$f\" ] && bash \"$f\""

# Frequency of data refresh once every 24 hours
#refreshFrequency: 86400000
refreshFrequency: 30000

# Styling for the widget
style: """
  // General widget styling
  top: 317px;
  left: 10px;
  color: var(--crystal-static, #fff);
  font-family: Helvetica Neue;
  background: rgba(#FFF, .1);
  padding: 10px 10px 2px;
  border-radius: 5px;
  width: 370px;

  .widget-title {
    font-size: 10px;
    text-transform: uppercase;
    font-weight: bold;
    margin-bottom: 6px;
  }

  .stat-row {
    font-size: 11px;
    font-weight: 300;
    color: var(--crystal-static-90, rgba(255,255,255,.9));
    text-shadow: 0 1px 0px rgba(#000, .7);
    margin-bottom: 4px; // Spacing between rows
    display: flex; // Use flexbox for layout
    justify-content: space-between; // Space out left and right data
  }

  .left-data {
    flex: 1; // Flex-grow to fill available space
    text-align: left;
    padding-right: 10px; // Add some padding for spacing
  }

  .right-data {
    flex: 1; // Flex-grow to fill available space
    text-align: right;
  }
"""

# Rendering the widget layout
render: ->
  """
  <div class="container">
    <div class="widget-title">System</div>
    <div class="stat-row">
      <span class="left-data">Loading...</span>
      <span class="right-data">Loading...</span>
    </div>
    <div class="stat-row">
      <span class="left-data">Loading...</span>
      <span class="right-data">Loading...</span>
    </div>
    <div class="stat-row">
      <span class="left-data">Loading...</span>
      <span class="right-data">Loading...</span>
    </div>
  </div>
  """

# Updating the widget with new data from the script
update: (output, domEl) ->
  values = output.trim().split(";")

  if values.length >= 6
    $(domEl).find(".stat-row").eq(0).find(".left-data").text values[0]
    $(domEl).find(".stat-row").eq(0).find(".right-data").text values[1]
    $(domEl).find(".stat-row").eq(1).find(".left-data").text values[2]
    $(domEl).find(".stat-row").eq(1).find(".right-data").text values[3]
    $(domEl).find(".stat-row").eq(2).find(".left-data").text values[4]
    $(domEl).find(".stat-row").eq(2).find(".right-data").text values[5]


