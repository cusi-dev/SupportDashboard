class Dashing.Table extends Dashing.Widget

    onData: (data) ->
        console.log 'table widget data: ', data
        console.log 'table widget node: ', $(@node)
        console.log 'table widget height: ', $(@node).height()
