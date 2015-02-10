class Dashing.GoogleGauge extends Dashing.Widget

  @accessor 'current'

  ready: ->

    container = $(@node).parent()
  # Gross hacks. Let's fix this.
    width = (Dashing.widget_base_dimensions[0] * container.data("sizex")) + Dashing.widget_margins[0] * 2 * (container.data("sizex") - 1)
    height = (Dashing.widget_base_dimensions[1] * container.data("sizey"))

    @chart = new google.visualization.Gauge($(@node).find(".gauge")[0])
    @options =
      greenFrom: @get('green_from')
      greenTo: @get('green_to')
      yellowFrom: @get('yellow_from')
      yellowTo: @get('yellow_to')
      redFrom: @get('red_from')
      redTo: @get('red_to')
      minorTicks: @get('minor_ticks') || 5
      min: @get('min')
      max: @get('max')
      height: height
      width: width

    if @get('current')
      @data = google.visualization.arrayToDataTable [['Label','Value'], [@get('title'), @get('current')]]
    else
      @data = google.visualization.arrayToDataTable [['Label','Value'], [@get('title'),0]]

    @chart.draw @data, @options

  onData: (data) ->
    if @chart
      @data = google.visualization.arrayToDataTable [['Label','Value'], [@get('title'), @get('current')]]
      @chart.draw @data, @options
