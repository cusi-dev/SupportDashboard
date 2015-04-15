class Dashing.DashingState extends Dashing.Widget

  @accessor 'widgetStates', ->
    checks = []
    for key, item of @get('detailed_status')
      checks = checks.concat(item)

    checks