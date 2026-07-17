# crystal-top-cpu.widget by locupleto
#
# https://github.com/locupleto/crystal-widgets

command: "ps axro \"%cpu,ucomm,pid\" | awk 'FNR>1' | tail +1 | head -n 3 | sed -e 's/^[ ]*\\([0-9][0-9]*\\.[0-9][0-9]*\\)\\ /\\1\\%\\,/g' -e 's/\\ \\ *\\([0-9][0-9]*$\\)/\\,\\1/g'"

refreshFrequency: 2000

style: """
top: 496px; //300px
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
  padding-right: 5px;
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

"""

render: ->
  """
  <table>
    <tr>
      <td colspan='3' class='table-header'>CPU top</td>
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

  for process, i in processes
    args = process.split(',')
    table.find(".col#{i+1}").html renderProcess(args...)

