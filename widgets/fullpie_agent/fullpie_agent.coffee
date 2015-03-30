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

    #mFontSize = 28
    width = 750 #width
    height = 450 #height
    radiuso = 135 #outer radius
    radiusi = 90 #inner radius
    labelRadius = 180

    #color = d3.scale.ordinal()
      #.domain([1,10])
    #  .domain([0,2])
      #.range( ['#222222','#555555','#777777','#999999','#bbbbbb','#dddddd','#ffffff'] )
      #.range( ['#222222','#333333','#444444','#555555','#666666','#777777','#888888','#999999','#aaaaaa'] )
    #  .range( ['#111111','#222222','#333333','#444444','#555555','#666666','#777777','#888888','#999999','#aaaaaa','#bbbbbb','#cccccc'] )
    color = d3.scale.category20()

    $(@node).children("svg").remove();

    vis = d3.select(@node).append("svg:svg")
      .data([data])
        .attr("width", width)
        .attr("height", height)
      .append("svg:g")
        .attr("transform", "translate(" + width/2 + "," + height/2 + ")") 

    arc = d3.svg.arc()
      .outerRadius(radiuso)
      .innerRadius(radiusi)

    pie = d3.layout.pie().value((d) -> d.value)

    arcs = vis.selectAll("g.slice")
      .data(pie)
      .enter().append("svg:g").attr("class", "slice") 

    defs = arcs.append("defs")
    filter = defs.append("filter")
        .attr("id","dropshadow")
    filter.append("feGaussianBlur")
        .attr("in","SourceAlpha")
        .attr("stdDeviation","1.1")
        .attr("result","blur")
    filter.append("feOffset")
        .attr("in","blur")
        .attr("dx",2)
        .attr("dy",2)
        .attr("result","offsetBlur")
    feMerge = filter.append("feMerge")
    feMerge.append("feMergeNode")
        .attr("in","offsetBlur")
    feMerge.append("feMergeNode")
        .attr("in","SourceGraphic")

    arcs.append("svg:path").attr("fill", (d, i) -> color i)
      .attr("fill-opacity", 0.7).attr("d", arc)
      .attr("filter","url(#dropshadow)")

    sum=0
    for val in data  
      sum += val.value

    if !sum
      arcs.append("svg:text").attr("class","cusipie-label")
        .attr('fill', "#fff")
        .attr("text-anchor", "middle").text("No Results")#.attr('font-size', mFontSize + 'px')
    else
      arcs.append("svg:text").attr("class","cusipie-sum")
        .attr('fill', "#fff")
        .attr("text-anchor", "middle")
        .attr("alignment-baseline", "mathematical")
        .attr('font-size', radiusi*1.3 + 'px')
        .attr('font-weight', 'bold')
        .text(sum)
        .attr("filter","url(#dropshadow)")

      arcs.append("svg:text").attr("transform", (d, i) -> 
        #procent_val = Math.round(data[i].value/sum * 100)
        #d.innerRadius = (radiuso * (100-procent_val)/100) - radiuso/2 #45  #45=max text size/2
        #d.innerRadius = 0 #(radiuso * (100-procent_val)/100) - radiuso/2 #45  #45=max text size/2
        #d.outerRadius = radiuso
        #"translate(" + arc.centroid(d) + ")")

        c = arc.centroid(d)
        x = c[0]
        y = c[1]
        mx = 1.6
        my = .8
        h = Math.sqrt(x*x + y*y)
        r = labelRadius
        if x <= 0
            r = -r
        if x < 0 and y < 0 and x > -radiusi and x/y < 1
            x = x * mx
            y = y * my
        return "translate(" + (x/h * labelRadius) + "," + (y/h * labelRadius) + ")"
        #return "translate(" + r + "," + y + ")"#(y/h * labelRadius) + ")"
        #return "translate(" + ((x/h * labelRadius)+r/4) + "," + y*my + ")"#(y/h * labelRadius) + ")"
        #return "translate(" + (x+r/2)*mx + "," + y*my + ")"
        #return "translate(" + (x/h * labelRadius)*mx + "," + (y/h * labelRadius)*my + ")"
        )

        .append("svg:tspan").attr("class","cusipie-label")

        .attr('fill', "#fff")
        .attr("text-anchor", "middle").text((d, i) -> 
          if data[i].value != 0
            #data[i].label
            data[i].label + " - " + data[i].value
        )
        #.attr('font-size', mFontSize + 'px')
        .attr("filter","url(#dropshadow)")
        .append('svg:tspan').attr("class","cusipie-label-percent")
        .attr('x', 0)
        .attr('dy', '.9em')
        #.attr('font-size', '70%')
        .text((d,i) -> 
          if data[i].value != 0
            #data[i].value + ' (' + Math.round(data[i].value/sum * 100) + '%)'
            '(' + Math.round(data[i].value/sum * 100) + '%)'
        )
