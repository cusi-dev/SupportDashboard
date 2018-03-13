class Dashing.Fullpie extends Dashing.Widget
  @accessor 'value'

  onData: (data) ->
    #$(@node).fadeOut().fadeIn()
    @render(data.value)
  
  render: (data) ->
    if !data
      data = @get("value")
    if !data
       return
    #console.log "FullPie new"
    # this is a fix because data binding seems otherwise not work 
    $(@node).children(".title").text($(@node).attr("data-title"))
    $(@node).children(".more-info").text($(@node).attr("data-moreinfo"))
    $(@node).children(".updated-at").text(@get('updatedAtMessage'))

    width = 260 #width
    height = 260 #height
    radius = 130 #radius

    color = d3.scale.ordinal()
      #.domain([1,10])
      .domain([0,2])
      #.range( ['#222222','#555555','#777777','#999999','#bbbbbb','#dddddd','#ffffff'] )
      #.range( ['#222222','#333333','#444444','#555555','#666666','#777777','#888888','#999999','#aaaaaa'] )
      .range( ['#4498ed','#9844ed','#4444ee'] )
      #.range( ['#00c116','#FA8728','#7F0000'] )

    $(@node).children("svg").remove();

    vis = d3.select(@node).append("svg:svg")
      .data([data])
        .attr("width", width)
        .attr("height", height)
      .append("svg:g")
        .attr("transform", "translate(" + radius + "," + radius + ")") 

    arc = d3.svg.arc().outerRadius(radius)
    pie = d3.layout.pie().value((d) -> d.value).sort(null)
	
    arcs = vis.selectAll("g.slice")
      .data(pie)
      .enter().append("svg:g").attr("class", "slice") 

    arcs.append("svg:path").attr("fill", (d, i) -> color i)
      .attr("fill-opacity", 0.4).attr("d", arc)

    sum=0
    for val in data  
      sum += val.value

# Core
#    arcs.append("svg:text").attr("transform", (d, i) -> 
#      procent_val = Math.round(data[i].value/sum * 100)
#      d.innerRadius = (radius * (100-procent_val)/100) - 45  #45=max text size/2
#      d.outerRadius = radius
#      "translate(" + arc.centroid(d) + ")")
#      .attr('fill', "#fff")
#      .attr("text-anchor", "middle").text((d, i) -> data[i].label).attr('font-size', '28px')
#      .append('svg:tspan')
#      .attr('x', 0)
#      .attr('dy', 25)
#      .attr('font-size', '90%')
#      .text((d,i) -> data[i].value + ' (' + Math.round(data[i].value/sum * 100) + '%)')

    if !sum
      arcs.append("svg:text")
        .attr('fill', "#fff")
        .attr("text-anchor", "middle").text("No Results").attr('font-size', '28px')
    else
      arcs.append("svg:text").attr("transform", (d, i) -> 
        procent_val = Math.round(data[i].value/sum * 100)
        d.innerRadius = (radius * (100-procent_val)/100) - 45  #45=max text size/2
        d.outerRadius = radius
        "translate(" + arc.centroid(d) + ")")
        .attr('fill', "#fff")
        .attr("text-anchor", "middle").text((d, i) -> 
          if data[i].value != 0
            data[i].label
        ).attr('font-size', '28px')
        .append('svg:tspan')
        .attr('x', 0)
        .attr('dy', '.9em')
        .attr('font-size', '80%')
        .text((d,i) -> 
          if data[i].value != 0
            data[i].value + ' (' + Math.round(data[i].value/sum * 100) + '%)'
		)

