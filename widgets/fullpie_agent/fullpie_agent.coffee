class Dashing.FullpieAgent extends Dashing.Widget

    @accessor 'data'

    constructor: ->
        super
        @instanceDataId = ''
        @oldPieData = {}
        
    ready: ->
        @instanceDataId = $(@node).attr('data-id')
        window.oldPieData = window.oldPieData or {}
        window.oldPieData[@instanceDataId] = window.oldPieData[@instanceDataId] or []

    onData: (data) ->
        #$(@node).fadeOut().fadeIn()

        # Define the container
        @container = $(@node).parent()
        console.log 'node',$(@node)
        console.log 'container',@container

        #
        # CONFIG ZONE
        #

        # Width of the SVG area
        @width = (Dashing.widget_base_dimensions[0] * @container.data('sizex')) - Dashing.widget_margins[0] * 4 * (@container.data('sizex') - 1) 

        # Height of the SVG area allowing for header and footer text
        @height = (Dashing.widget_base_dimensions[1] * @container.data('sizey')) - 120 

        # Calculated min dimension of the SVG area
        @radius = Math.min(@width, @height) / 2

        # Outer radius of the pie
        @radiuso = Math.min(@width, @height) / 3

        # Inner radius of the pie (zero = pie, non-zero = donut)
        @radiusi = @radiuso * 2 / 3

        # Color scale for pie slices
        @color = d3.scale.category20()

        # X-offset for drop shadow filter
        @dropshadowx = 2

        # Y-offset for drop shadow filter
        @dropshadowy = 2

        # [STRING] Blur value for drop shadow filter
        @dropshadowblur = '1.2'

        #
        # END CONFIG ZONE
        #

        @update(data.data)

    update: (dataSet) ->
        # Remove any previous svg
        $(@node).children('svg').remove()

        width = @width
        height = @height
        radius = @radius
        radiuso = @radiuso
        radiusi = @radiusi
        color = @color
        dropshadowx = @dropshadowx
        dropshadowy = @dropshadowy
        dropshadowblur = @dropshadowblur
        
        if !dataSet
            dataSet = @get('data')
        if !dataSet
            return

        pie = d3.layout.pie().value((d) -> d.value).sort(null)
        arc = d3.svg.arc().innerRadius(radiusi).outerRadius(radiuso)
        svg = d3.select(@node).append('svg').attr('width', width).attr('height', height).append('g').attr('transform', 'translate(' + width / 2 + ',' + height / 2 + ')')

        piedata = pie(dataSet)

        # Remove zero values from our pie data
        piedata = piedata.filter (pd) -> pd.value isnt 0

        #create a marker element if it doesn't already exist
        defs = svg.select('defs')
        if defs.empty()
            defs = svg.append('defs')
        marker = defs.select('marker#circ')
        if marker.empty()
            defs.append('marker').attr('id', 'circ').attr('markerWidth', 9).attr('markerHeight', 9).attr('refX', 4).attr('refY', 4).append('circle').attr('cx', 4).attr('cy', 4).attr 'r', 4

        # Add drop shadow filter
        filter = defs.append('filter')
            .attr('id','dropshadow')
        filter.append('feGaussianBlur')
            .attr('in','SourceAlpha')
            .attr('stdDeviation',dropshadowblur)
            .attr('result','blur')
        filter.append('feOffset')
            .attr('in','blur')
            .attr('dx',dropshadowx)
            .attr('dy',dropshadowy)
            .attr('result','offsetBlur')
        feMerge = filter.append('feMerge')
        feMerge.append('feMergeNode')
            .attr('in','offsetBlur')
        feMerge.append('feMergeNode')
            .attr('in','SourceGraphic')

        # Create/select <g> elements to hold the different types of graphics
        # and keep them in the correct drawing order
        pathGroup = svg.select('g.piePaths')
        if pathGroup.empty()
            pathGroup = svg.append('g').attr('class', 'piePaths')
        pointerGroup = svg.select('g.pointers')
        if pointerGroup.empty()
            pointerGroup = svg.append('g').attr('class', 'pointers')
        labelGroup = svg.select('g.labels')
        if labelGroup.empty()
            labelGroup = svg.append('g').attr('class', 'labels')

        totalLabel = svg.select('g.totalLabel')
        if totalLabel.empty()
            totalLabel = svg.append('g').attr('class', 'totalLabel')

        # Create variable for old pie data that will be in scope within the path.transition attrTween function below
        # and handle null values that happen on browser refresh because onData() loads before ready()
        window.oldPieData ? @ready
        lastPieData = window.oldPieData[@instanceDataId] ? d

        path = pathGroup.selectAll('path.pie').data(piedata)
        path.enter().append('path').attr('class', 'pie').attr('fill', (d, i) -> color i)
        path.transition().duration(1000).attrTween('d', (d,i) ->
            s0 = undefined
            e0 = undefined
            if lastPieData[i]
                s0 = lastPieData[i].startAngle
                e0 = lastPieData[i].endAngle
            else if !lastPieData[i] and lastPieData[i - 1]
                s0 = lastPieData[i - 1].endAngle
                e0 = lastPieData[i - 1].endAngle
            else if !lastPieData[i - 1] and lastPieData.length > 0
                s0 = lastPieData[lastPieData.length - 1].endAngle
                e0 = lastPieData[lastPieData.length - 1].endAngle
            else
                s0 = 0
                e0 = 0
            myInterpolater = d3.interpolate({
                startAngle: s0
                endAngle: e0
            },{
                startAngle: d.startAngle
                endAngle: d.endAngle
            })
            return (t) ->
                return arc(myInterpolater(t))
        )
        path.exit()
            .transition()
            .duration(1000)
            .attrTween('d', (d,i) -> 
                s0 = 2 * Math.PI
                e0 = 2 * Math.PI
                exitInterpolater = d3.interpolate({
                    startAngle: d.startAngle
                    endAngle: d.endAngle
                },{
                    startAngle: s0
                    endAngle: e0
                })
                return (t) ->
                    return arc(exitInterpolater(t))
            )
            .remove()

        labels = labelGroup.selectAll('text').data(piedata.sort((p1, p2) ->
            p1.startAngle - p2.startAngle
        ))
        labels.enter().append('text').attr('text-anchor', 'middle').attr('font-size', radiusi * .3 + 'px').attr('filter','url(#dropshadow)')
        #labels.enter().append('text')
            #.attr('text-anchor', (d) ->
                #rads = ((d.endAngle - d.startAngle) / 2) + d.startAngle
                #if (rads > 3 * Math.PI / 4 && rads < 5 * Math.PI / 4)
                #    return "middle"
                #else if (rads >= 0 && rads <= 3 * Math.PI / 4)
                #    return "start"
                #else if (rads >= 5 * Math.PI / 4 && rads <= 8 * Math.PI / 4)
                #    return "end"
                #else
                #    return "middle"
            #)
            #.attr("filter","url(#dropshadow)")
        labels.exit().remove()
        labelLayout = d3.geom.quadtree().extent([
            [
                -width
                -height
            ]
            [
                width
                height
            ]
        ]).x((d) ->
            d.x
        ).y((d) ->
            d.y
        )([])

        # Create an instance name variable that will be in scope below
        myInstanceDataId = @instanceDataId

        #create an empty quadtree to hold label positions
        maxLabelWidth = 0
        maxLabelHeight = 0
        labels.text((d) ->
            # Set the text *first*, so we can query the size
            # of the label with .getBBox()
            d.data.label + ': ' + d.data.value
        )
        .style('opacity',0)
        .each((d, i) ->
            # Move all calculations into the each function.
            # Position values are stored in the data object 
            # so can be accessed later when drawing the line
            ### calculate the position of the center marker ###
            a = (d.startAngle + d.endAngle) / 2

            #trig functions adjusted to use the angle relative
            #to the "12 o'clock" vector:
            d.cx = Math.sin(a) * (radiuso - (radiuso - radiusi) / 2)
            d.cy = -Math.cos(a) * (radiuso - (radiuso - radiusi) / 2)

            ### calculate the default position for the label,
               so that the middle of the label is centered in the arc
            ###
            bbox = @getBBox()
            #bbox.width and bbox.height will 
            #describe the size of the label text
            labelRadius = radiuso + (radiuso - radiusi)
            d.x = Math.sin(a) * labelRadius
            d.l = d.x - bbox.width / 2 - 2
            d.r = d.x + bbox.width / 2 + 2
            d.y = -Math.cos(a) * (labelRadius)
            d.b = d.oy = d.y + 2#5
            d.t = d.y - bbox.height - 2#5

            ### check whether the default position 
               overlaps any other labels
            ###
            conflicts = []
            labelLayout.visit (node, x1, y1, x2, y2) ->
                #recurse down the tree, adding any overlapping 
                #node is the node in the quadtree, 
                #node.point is the value that we added to the tree
                #x1,y1,x2,y2 are the bounds of the rectangle that
                #this node covers

                if x1 > d.r + maxLabelWidth / 2 or x2 < d.l - maxLabelWidth / 2 or y1 > d.b + maxLabelHeight / 2 or y2 < d.t - maxLabelHeight / 2
                    return true # don't bother visiting children or checking this node
                p = node.point
                v = false
                h = false
                if p
                    #p is defined, i.e., there is a value stored in this node
                    h = p.l > d.l and p.l <= d.r or p.r > d.l and p.r <= d.r or p.l < d.l and p.r >= d.r
                    #horizontal conflict
                    v = p.t > d.t and p.t <= d.b or p.b > d.t and p.b <= d.b or p.t < d.t and p.b >= d.b
                    #vertical conflict
                    if h and v
                        conflicts.push p
                    #add to conflict list
                return

            if conflicts.length
                console.log myInstanceDataId , ' ', d, ' conflicts with ', conflicts
                rightEdge = d3.max(conflicts, (d2) ->
                    #`var maxLabelHeight`
                    #`var maxLabelWidth`
                    d2.r
                )
                d.l = rightEdge
                d.x = d.l + bbox.width / 2 + 5
                d.r = d.l + bbox.width + 10
            else
                console.log 'no conflicts for ', myInstanceDataId, ' ', d

            ### add this label to the quadtree, so it will show up as a conflict
               for future labels.  
            ###
            labelLayout.add d
            maxLabelWidth = Math.max(maxLabelWidth, bbox.width + 10)
            maxLabelHeight = Math.max(maxLabelHeight, bbox.height + 10)
            return
        )
        #.attr("x",0)
        #.attr("y",0)
        .transition()
            .delay(750)
            .duration(500)
            .attr('x', (d) ->
                d.x
            ).attr('y', (d) ->
                d.y
            ).style("opacity", 1)

        pointers = pointerGroup.selectAll('path.pointer').data(piedata)
        pointers.enter()
            .append('path')
            .attr('class', 'pointer')
            .style('fill', 'none')
            .style('stroke', 'black')
            .attr('stroke-width', 1.2)
            .attr('marker-end', 'url(#circ)')
            .style('opacity', 0)
        pointers.exit().remove()

        # Unable to make this pointer transition work.  They all snap and ignore transitioning.  The example
        # in pure Javascript works at http://jsfiddle.net/Qh9X5/1249/
        #pointers.transition().delay(1000).duration(500).attr('d', (d) ->
        #        if d.cx > d.l
        #            'M' + (d.l + 2) + ',' + d.b + 'L' + (d.r - 2) + ',' + d.b + ' ' + d.cx + ',' + d.cy
        #        else
        #            'M' + (d.r - 2) + ',' + d.b + 'L' + (d.l + 2) + ',' + d.b + ' ' + d.cx + ',' + d.cy
        #    )
        # Work-around broken smooth transitioning by using 0 opacity to hide the move
        pointers.attr('d', (d) ->
                if d.cx > d.l
                    'M' + (d.l + 2) + ',' + d.b + 'L' + (d.r - 2) + ',' + d.b + ' ' + d.cx + ',' + d.cy
                else
                    'M' + (d.r - 2) + ',' + d.b + 'L' + (d.l + 2) + ',' + d.b + ' ' + d.cx + ',' + d.cy
            )
        pointers.transition().delay(1000).duration(500).style('opacity',1)

        # Display total count
        totalTickets = 0
        for pd in dataSet
            totalTickets += pd.value
        totalTickets = if totalTickets != 0 then totalTickets else 'No Results'
        totalLabel.append('text')
            .text(totalTickets)
            .attr('font-size',radiusi * .1 + 'px')
            .attr('text-anchor', 'middle')
            .attr('alignment-baseline', 'central')
            .attr('filter','url(#dropshadow)')
            .style('opacity', 0)
        totalLabel.select('text').transition()
            .duration(500)
            .attr('font-size',(if typeof totalTickets isnt 'string' then radiusi + 'px' else radiusi / 2 + 'px'))
            .style('opacity', 1)

        window.oldPieData[@instanceDataId] = piedata

        return
