class Dashing.Testpie extends Dashing.Widget
  @accessor 'value'

  onData: (data) ->
    $(@node).fadeOut().fadeIn()
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
      #.range( ['#4e4eb1','#4eb14e','#b14e4e','#2727d8','#27d827','#d82727','#0000ff','#00ff00','#ff0000'] )
      #.range( ['#0000ff','#00ff00','#ff0000'] )
      .range( ['#cc9900','#ff0099','#4444ee'] )

    $(@node).children("svg").remove();

    vis = d3.select(@node).append("svg:svg")
      .data([data])
        .attr("width", width)
        .attr("height", height)
      .append("svg:g")
        .attr("transform", "translate(" + radius + "," + radius + ")") 

    arc = d3.svg.arc().outerRadius(radius)
    pie = d3.layout.pie().value((d) -> d.value)

    arcs = vis.selectAll("g.slice")
      .data(pie)
      .enter().append("svg:g").attr("class", "slice") 

    arcs.append("svg:path").attr("fill", (d, i) -> color i)
      .attr("fill-opacity", 0.4).attr("d", arc)

    sum=0
    for val in data  
      sum += val.value
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
        .attr('dy', 1em)
        .attr('font-size', '90%')
        .text((d,i) -> 
          if data[i].value != 0
            data[i].value
        )
        .append('svg:tspan')
        .attr('x', 0)
        .attr('dy', 1em)
        .attr('font-size', '70%')
        .text((d,i) -> 
          if data[i].value != 0
            '(' + Math.round(data[i].value/sum * 100) + '%)'
        )

# mod
#	arcs.append("svg:text").attr("transform", (d, i) -> 
#        procent_val = Math.round(data[i].value/sum * 100)
#        d.innerRadius = (radius * (100-procent_val)/100) - 45  #45=max text size/2
#        d.outerRadius = radius
#        "translate(" + arc.centroid(d) + ")")
#        .attr('fill', "#fff")
#        .attr("text-anchor", "middle").text((d, i) -> data[i].label).attr('font-size', '28px')
#        .append('svg:tspan')
#        .attr('x', 0)
#        .attr('dy', 25)
#        .attr('font-size', '90%')
#        .text((d,i) -> data[i].value + ' (' + Math.round(data[i].value/sum * 100) + '%)')

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
