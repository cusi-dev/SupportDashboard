class Dashing.FullpieAgent extends Dashing.Widget
  @accessor 'value'

  onData: (data) ->
    $(@node).fadeOut().fadeIn()
    @render(data.value)
  
  render: (data) ->
    if !data
      data = @get("value")
    if !data
      return

    $(@node).children(".title").text($(@node).attr("data-title"))
    $(@node).children(".more-info").text($(@node).attr("data-moreinfo"))
    $(@node).children(".updated-at").text(@get('updatedAtMessage'))

    mFontSize = 28
	
    width = 400 #width
    height = 400 #height
    radiuso = 200 #outer radius
    radiusi = 100 #inner radius

    color = d3.scale.ordinal()
      #.domain([1,10])
      .domain([0,2])
      #.range( ['#222222','#555555','#777777','#999999','#bbbbbb','#dddddd','#ffffff'] )
      #.range( ['#222222','#333333','#444444','#555555','#666666','#777777','#888888','#999999','#aaaaaa'] )
      .range( ['#111111','#222222','#333333','#444444','#555555','#666666','#777777','#888888','#999999','#aaaaaa','#bbbbbb','#cccccc'] )

    $(@node).children("svg").remove();

    vis = d3.select(@node).append("svg:svg")
      .data([data])
        .attr("width", width)
        .attr("height", height)
      .append("svg:g")
        .attr("transform", "translate(" + radiuso + "," + radiuso + ")") 

    arc = d3.svg.arc()
      .outerRadius(radiuso)
      .innerRadius(radiusi)

    pie = d3.layout.pie().value((d) -> d.value)

    arcs = vis.selectAll("g.slice")
      .data(pie)
      .enter().append("svg:g").attr("class", "slice") 

    arcs.append("svg:path").attr("fill", (d, i) -> color i)
      .attr("fill-opacity", 0.4).attr("d", arc)

    sum=0
    for val in data  
      sum += val.value
    textRadiusInc = Math.Round(sum / data.count)
    if !sum
      arcs.append("svg:text")
        .attr('fill', "#fff")
        .attr("text-anchor", "middle").text("No Results").attr('font-size', '28px')
    else
      arcs.append("svg:text").attr("transform", (d, i) -> 
        procent_val = Math.round(data[i].value/sum * 100)
        #d.innerRadius = (radiuso * (100-procent_val)/100) - radiuso/2 #45  #45=max text size/2
        d.innerRadius = (radiuso * (100-procent_val)/100) - radiuso/2 #45  #45=max text size/2
        d.outerRadius = radiuso
        "translate(" + arc.centroid(d) + ")")
        .attr('fill', "#fff")
        .attr("text-anchor", "middle").text((d, i) -> 
          if data[i].value != 0
            data[i].label
        ).attr('font-size', mFontSize + 'px')
        .append('svg:tspan')
        .attr('x', 0)
        .attr('dy', '.9em')
        .attr('font-size', '80%')
        .text((d,i) -> 
          if data[i].value != 0
            data[i].value + ' (' + Math.round(data[i].value/sum * 100) + '%)'
        )
