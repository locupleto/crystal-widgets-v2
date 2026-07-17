# crystal-top-mem.widget by locupleto
#
# https://github.com/locupleto/crystal-widgets

command: "ps axo \"rss,pid,ucomm\" | sort -nr | tail +1 | head -n3 | awk '{printf \"%8.0f MB,%s,%s\\n\", $1/1024, $3, $2}'"

refreshFrequency: 5000

style: """
top: 760px; //564px//476px//
left: 10px
color: #fff
font-family: Helvetica Neue

table
  border-collapse: collapse
  table-layout: fixed
  background: rgba(#fff, 0.1) // Uniform background for the entire table
  border-radius: 5px
  width: 390px // Set the width to match the other tables

.table-header
  font-size: 10px
  font-weight: bold // Make the header text bold
  text-align: left
  padding: 10px 6px
  border-radius: 5px
  width: 100% // Ensures the header spans the full width of the table

td
  font-size: 12px
  font-weight: 100
  width: 130px
  max-width: 130px
  overflow: hidden
  text-shadow: 0 0 1px rgba(#000, 0.5)

.wrapper
  padding: 4px 6px 4px 6px
  position: relative
  width: 100%;

.col1, .col2, .col3
  border-radius: 5px // Maintain border-radius but remove individual backgrounds

.col1 {
  font-weight: normal;
  color: #ddd;
  text-align: left;  // Align text to the left in the first column
}

.col2 {
  font-weight: normal;
  color: #ddd;
  text-align: left;  // Align text to the left in the second column
  padding-left: 15px;
}

.col3 {
  font-weight: normal;
  color: #ddd;
  text-align: right;  // Align text to the right in the third column
  padding-right: 15px;
}


p
  padding: 0
  margin: 0
  font-size: 11px
  font-weight: normal
  max-width: 100%
  color: #ddd
  text-overflow: ellipsis

.pid
    font-size: 11px
    font-weight: normal
    color: #ddd
    padding-right: 6px
    width: 100%;
    
"""

render: ->
  """
  <table>
    <tr>
      <td colspan='3' class='table-header'>MEM top</td>
    </tr>
    <tr>
      <td class='col1'></td>
      <td class='col2'></td>
      <td class='col3'></td>
    </tr>
  </table>
  """


update: (output, domEl) ->
  processes = output.split('\n')
  table     = $(domEl).find('table')

  renderProcess = (cpu, name, id) ->
    "<div class='wrapper'>" +
      "#{cpu}<p>#{name}</p>" +
      "<div class='pid'>#{id}</div>" +
    "</div>"

# Loop through each process and update the corresponding table column
  for process, i in processes
    [cpu, name, id] = process.split(',')
    table.find(".col#{i+1}").html renderProcess(cpu, name, id)

