class Dashing.NagiosList extends Dashing.Widget
  @accessor 'hasCritical', ->
    if (@get('critical') && @get('critical').length > 0) then true else false
  @accessor 'hasWarning', ->
    if (@get('warning') && @get('warning').length > 0) then true else false

  @accessor 'criticalMap', ->
    @_groupBy(@get('critical'))

  @accessor 'warningMap', ->
    @_groupBy(@get('warning'))

  @accessor 'okMap', ->
    @_groupBy(@get('ok'))

  ready: ->
    node = $(@node)
    style = 'overflow': 'hidden'
    node.parent().css(style)

  clear: ->


  _groupBy: (items) ->
    maps = {}
    items = items || []
    for item, index in items
      item.last_check = @_parseTime(item.last_check)
      if !maps[item.host]
        maps[item.host] = [item]
      else
        maps[item.host] = maps[item.host].concat item

    results = []
    for key, item of maps
      node = host: key, checks: item
      results = results.concat node

    return results

  _parseTime: (timestamp) ->
    time = new Date(timestamp)
    return "#{@_toTwoDigits(time.getHours())}:#{@_toTwoDigits(time.getMinutes())}"

  _toTwoDigits: (val) ->
    val = val + ''
    if val.length == 1
      return "0#{val}"

    return val
