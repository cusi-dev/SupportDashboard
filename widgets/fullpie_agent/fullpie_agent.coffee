class Dashing.FullpieAgent extends Dashing.Widget
  @accessor 'value'

  onData: (data) ->
    $(@node).fadeOut().fadeIn()
    @render(data.value)
  
  renderX: (data) ->
    if !data
      data = @get("value")
    if !data
      return

    $(@node).children(".title").text($(@node).attr("data-title"))
    $(@node).children(".more-info").text($(@node).attr("data-moreinfo"))
    $(@node).children(".updated-at").text(@get('updatedAtMessage'))

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
        mx = 1.7
        my = 1
        h = Math.sqrt(x*x + y*y)
        r = labelRadius
        if x <= 0
            r = -r
        if x < 0 and y < 0 and x > -radiusi and x/y < 1.2
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
        .attr("text-anchor", "middle")
        .text((d, i) -> 
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

  pieTween: (d, i) ->

        i = d3.interpolate({startAngle: 0,endAngle: 0}, {startAngle: d.startAngle,endAngle: d.endAngle})

        return (t) -> 
            b = i(t);
            return arc(b)

  renderX3: (data) ->

        if !data
          data = @get("value")
        if !data
          return

        $(@node).children(".title").text($(@node).attr("data-title"))
        $(@node).children(".more-info").text($(@node).attr("data-moreinfo"))
        $(@node).children(".updated-at").text(@get('updatedAtMessage'))

        # Build pie

        width = 750
        height = 450
        radiuso = 135 #outer radius
        radiusi = 90 #inner radius
        radius = Math.min(width, height) / 2 #palette radius min
        labelRadius = 180

        color = d3.scale.category20()

        $(@node).children("svg").remove();

        arc = d3.svg.arc().outerRadius(radius)
        pie = d3.layout.pie().value((d) -> d.value)
	
        svg = d3.select(@node).append("svg:svg")
          .data([data])
            .attr("width", width)
            .attr("height", height)
          .append("svg:g")
            .attr("transform", "translate(" + radius + "," + radius + ")") 

        arcs = svg.selectAll("g.slice")
          .data(pie)
          .enter().append("svg:g").attr("class", "slice") 

        arcs.append("svg:path").attr("fill", (d, i) -> color i)
          .attr("fill-opacity", 0.4).attr("d", arc)

  render: (data) ->
        #console.log("update pie", data);

        if !data
          data = @get("value")
        if !data
          return

        piedata = [data]

        $(@node).children(".title").text($(@node).attr("data-title"))
        $(@node).children(".more-info").text($(@node).attr("data-moreinfo"))
        $(@node).children(".updated-at").text(@get('updatedAtMessage'))

        # Build pie

        width = 750
        height = 450
        radiuso = 135 #outer radius
        radiusi = 90 #inner radius
        radius = Math.min(width, height) / 2 #palette radius min
        labelRadius = 180

        color = d3.scale.category20()

        $(@node).children("svg").remove();

        #svg = d3.select(@node).append("svg:svg")
        #    .attr("width", width)
        #    .attr("height", height)
        #    .append("svg:g")
        #    .attr("transform", "translate(" + width/2 + "," + height/2 + ")") 
        svg = d3.select(@node).append("svg")
            .attr("width", width)
            .attr("height", height)
            .append("g")
            .attr("transform", "translate(" + width/2 + "," + height/2 + ")") 

        pie = d3.layout.pie()
            .sort(null)
            #.value((d) -> d.value)

        arc = d3.svg.arc()
          .outerRadius(radiuso)
          .innerRadius(radiusi)

        #arcs = svg.selectAll("g.slice")
        #    .data(pie)
        #    .enter().append("svg:g").attr("class", "slice") 

        #arcs.append("svg:path").attr("fill", (d, i) -> color i)
        #    .attr("fill-opacity", 0.4).attr("d", arc)

        # end Build pie
        #console.log("update pie", data);

        #create a marker element if it doesn't already exist
        defs = svg.select("defs")
        if defs.empty() 
            defs = svg.append("defs")

        marker = defs.select("marker#circ")
        if marker.empty() 
            defs.append("marker")
            .attr("id", "circ")
            .attr("markerWidth", 6)
            .attr("markerHeight", 6)
            .attr("refX", 3)
            .attr("refY", 3)
            .append("circle")
            .attr("cx", 3)
            .attr("cy", 3)
            .attr("r", 3)
        
        #Create/select <g> elements to hold the different types of graphics
        #and keep them in the correct drawing order
        pathGroup = svg.select("g.piePaths")
        if pathGroup.empty()
            pathGroup = svg.append("g").attr("class", "piePaths")
        
        pointerGroup = svg.select("g.pointers")
        if pointerGroup.empty()
            pointerGroup = svg.append("g").attr("class", "pointers")
        
        labelGroup = svg.select("g.labels")
        if labelGroup.empty()
            labelGroup = svg.append("g").attr("class", "labels")
        
        #path = pathGroup.selectAll("path.pie")
        #    .data(piedata)

        #path.enter().append("path")
        #    .attr("class", "pie")
        #    .attr("fill",(d, i) -> return color i)

        path = pathGroup.selectAll("path.pie")
            .data(piedata)
            .enter().append("g").attr("class","slice")

        path.append("path")
            .attr("fill",(d, i) -> return color i).attr("d",arc)

        #arcs = svg.selectAll("g.slice")
        #    .data(pie)
        #    .enter().append("svg:g").attr("class", "slice") 

        #arcs.append("svg:path").attr("fill", (d, i) -> color i)
        #    .attr("fill-opacity", 0.4).attr("d", arc)

        

        #path.transition()
        #    .duration(1500)
        #    .attrTween("d", @pieTween);

        #path.exit()
        #    .transition()
        #    .duration(300)
        #    .attrTween("d", @removePieTween)
        #    .remove();

        #path.transition()
        #    .duration(1500)
        #    #.attrTween("d", pieTween)
        #    .attrTween("d", (d,i) -> 
        #        console.log("d",d)
        #        console.log("i",i)
        #        #i = d3.interpolate({startAngle: 0, endAngle: 0}, {startAngle: d.startAngle, endAngle: d.endAngle})
        #        i = d3.interpolate({startAngle: 0, endAngle: 0}, {startAngle: 90, endAngle: 135})
        #        return (t) -> 
        #            b = i(t)
        #            return arc(b)
        #    )

        #path.exit()
        #    .transition()
        #    .duration(300)
        #    .attrTween("d", (d,i) -> 
        #        i = d3.interpolate({startAngle: d.startAngle,endAngle: d.endAngle},{startAngle: 2 * Math.PI,endAngle: 2 * Math.PI})
        #        return (t) -> 
        #            b = i(t)
        #            return arc(b)
        #    )
        #    .remove()
        labels = labelGroup.selectAll("text")
            .data(piedata.sort((p1,p2) -> return p1.startAngle - p2.startAngle))
        labels.enter()
            .append("text")
            .attr("text-anchor", "middle")
        labels.exit()
            .remove()

        labelLayout = d3.geom.quadtree()
            .extent([[-width,-height], [width,height] ])
            .x((d) -> return d.x)
            .y((d) -> return d.y)
            ([]) #create an empty quadtree to hold label positions

        maxLabelWidth = 0
        maxLabelHeight = 0
        
        #labels.text((d) ->
            # Set the text *first*, so we can query the size
            # of the label with .getBBox()
        #    return d.value
        #)
        #.each((d, i) ->
            # Move all calculations into the each function.
            # Position values are stored in the data object 
            # so can be accessed later when drawing the line
            
            # calculate the position of the center marker
        #    a = (d.startAngle + d.endAngle) / 2 
            
            #trig functions adjusted to use the angle relative
            #to the "12 o'clock" vector:
        #    d.cx = Math.sin(a) * (radius - 75)
        #    d.cy = -Math.cos(a) * (radius - 75)
            
            # calculate the default position for the label,
            #   so that the middle of the label is centered in the arc
        #    bbox = this.getBBox()
            #bbox.width and bbox.height will 
            #describe the size of the label text
        #    labelRadius = radius - 20
        #    d.x =  Math.sin(a) * (labelRadius)
        #    d.l = d.x - bbox.width / 2 - 2
        #    d.r = d.x + bbox.width / 2 + 2
        #    d.y = -Math.cos(a) * (radius - 20)
        #    d.b = d.oy = d.y + 5
        #    d.t = d.y - bbox.height - 5 
            
            # check whether the default position 
            #   overlaps any other labels
        #    conflicts = []
            #labelLayout.visit( (node, x1, y1, x2, y2) -> 
                #recurse down the tree, adding any overlapping 
                #node is the node in the quadtree, 
                #node.point is the value that we added to the tree
                #x1,y1,x2,y2 are the bounds of the rectangle that
                #this node covers
                
                #1. left edge of node is to the right of right edge of label
                #2. right edge of node is to the left of left edge of label
                #3. top (minY) edge of node is greater than the bottom of label
                #4. bottom (maxY) edge of node is less than the top of label
            #    if  (x1 > d.r + maxLabelWidth/2) or (x2 < d.l - maxLabelWidth/2) or (y1 > d.b + maxLabelHeight/2) or (y2 < d.t - maxLabelHeight/2 )
            #        return true #don't bother visiting children or checking this node
                
            #    p = node.point
            #    v = false
            #    h = false
            #    if p #p is defined, i.e., there is a value stored in this node
            #        h =  ( ((p.l > d.l) and (p.l <= d.r)) or ((p.r > d.l) and (p.r <= d.r)) or ((p.l < d.l) and (p.r >=d.r) ) ) #horizontal conflict
            #        v =  ( ((p.t > d.t) and (p.t <= d.b)) or ((p.b > d.t) and (p.b <= d.b)) or ((p.t < d.t) and (p.b >=d.b) ) ) #vertical conflict
            #        if h and v
            #            conflicts.push(p) #add to conflict list
            #)
            
        #    if conflicts.length 
        #        console.log(d, " conflicts with ", conflicts);  
        #        rightEdge = d3.max(conflicts, (d2) ->
        #            return d2.r
        #        )

        #        d.l = rightEdge
        #        d.x = d.l + bbox.width / 2 + 5
        #        d.r = d.l + bbox.width + 10
            
        #    else console.log("no conflicts for ", d)
            
            # add this label to the quadtree, so it will show up as a conflict
            #   for future labels.  
            #labelLayout.add( d )
        #    maxLabelWidth = Math.max(maxLabelWidth, bbox.width+10)
        #    maxLabelHeight = Math.max(maxLabelHeight, bbox.height+10)
        #)
        #.transition() #we can use transitions now!
        #.attr("x", (d) ->
        #            return d.x
        #        )
        #        .attr("y", (d) ->
        #            return d.y
        #        )


        #pointers = pointerGroup.selectAll("path.pointer")
        #    .data(piedata)
        #pointers.enter()
        #    .append("path")
        #    .attr("class", "pointer")
        #    .style("fill", "none")
        #    .style("stroke", "black")
        #    .attr("marker-end", "url(#circ)")
        #pointers.exit().remove()
        
        #pointers.transition().attr("d", (d) ->
        #    if d.cx > d.l
        #        return "M" + (d.l+2) + "," + d.b + "L" + (d.r-2) + "," + d.b + " " + d.cx + "," + d.cy
        #    else
        #        return "M" + (d.r-2) + "," + d.b + "L" + (d.l+2) + "," + d.b + " " + d.cx + "," + d.cy
        #    
        #)

  renderX5: (data) ->
        #console.log("update pie", data);

        if !data
          data = @get("value")
        if !data
          return
        
        piedata = [data]

        $(@node).children(".title").text($(@node).attr("data-title"))
        $(@node).children(".more-info").text($(@node).attr("data-moreinfo"))
        $(@node).children(".updated-at").text(@get('updatedAtMessage'))

        # Build pie

        width = 750
        height = 450
        radiuso = 135 #outer radius
        radiusi = 90 #inner radius
        radius = Math.min(width, height) / 2 #palette radius min
        labelRadius = 180

        color = d3.scale.category20()

        $(@node).children("svg").remove();

        #svg = d3.select(@node).append("svg:svg")
        #    .data([data])
        #    .attr("width", width)
        #    .attr("height", height)
        #    .append("svg:g")
        #    .attr("transform", "translate(" + width/2 + "," + height/2 + ")") 
        svg = d3.select(@node).append("svg")
            .data(piedata)
            .attr("width", width)
            .attr("height", height)
            .append("g")
            .attr("transform", "translate(" + width/2 + "," + height/2 + ")") 

        pie = d3.layout.pie()
            #.sort(null)
            .value((d) -> d.value)

        arc = d3.svg.arc()
          .outerRadius(radiuso)
          .innerRadius(radiusi)

        arcs = svg.selectAll("g.slice")
            .data(pie)
            .enter().append("svg:g").attr("class", "slice") 

        arcs.append("svg:path").attr("fill", (d, i) -> color i)
            .attr("fill-opacity", 0.4).attr("d", arc)

        # end Build pie
        #console.log("update pie", data);

