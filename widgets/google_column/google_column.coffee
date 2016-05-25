class Dashing.GoogleColumn extends Dashing.Widget

  @accessor 'current', ->
    return @get('displayedValue') if @get('displayedValue')
    points = @get('points')
    if points
      points[points.length - 1].y

  ready: ->
    container = $(@node).parent()
  # Gross hacks. Let's fix this.
    width = (Dashing.widget_base_dimensions[0] * container.data("sizex")) + Dashing.widget_margins[0] * 2 * (container.data("sizex") - 1)
    height = (Dashing.widget_base_dimensions[1] * container.data("sizey"))

    colors = null
    if @get('colors')
      colors = @get('colors').split(/\s*,\s*/)

    @chart = new google.visualization.ColumnChart($(@node).find(".chart")[0])
    @options =
      height: height
      width: width
      colors: colors
      backgroundColor:
        fill:'transparent'
      isStacked: @get('is_stacked')
      legend:
        position: @get('legend_position'),
        textStyle:
          fontSize: 24,
          opacity: 0.8,
          color: 'white'
      animation:
        duration: 500,
        easing: 'out'
      chartArea:
        width: '80%',
        height: '80%'
      annotations:
        textStyle:
          fontSize: 48,
          bold: true,
          auraColor: 'white',
          opacity: 0.8
      vAxis:
        color: 'white',
        opacity: '80%',
        textStyle:
          fontSize: 16,
          opacity: 0.8,
          color: 'white'
        viewWindow:
          min: 0
      hAxis:
        color: 'white',
        opacity: '80%',
        textStyle:
          fontSize: 26,
          opacity: 0.8,
          color: 'white'
      tooltip:
        textStyle:
          fontSize: 24,
          opacity: 0.8,
          color: 'black'
        

    if @get('points')
      @data = google.visualization.arrayToDataTable @get('points')
    else
      @data = google.visualization.arrayToDataTable []

    @chart.draw @data, @options

  onData: (data) ->
    if @chart
      @data = google.visualization.arrayToDataTable data.points
      @chart.draw @data, @options
