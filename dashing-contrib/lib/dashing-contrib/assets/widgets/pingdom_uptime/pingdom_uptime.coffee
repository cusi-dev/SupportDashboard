class Dashing.PingdomUptime extends Dashing.Widget
  @accessor 'current', Dashing.AnimatedValue
  @accessor 'first', Dashing.AnimatedValue
  @accessor 'firstTitle', Dashing.AnimatedValue
  @accessor 'second', Dashing.AnimatedValue
  @accessor 'secondTitle', Dashing.AnimatedValue
  @accessor 'arrowClass', ->
    if (@get('is_up') == true) then 'fa fa-smile-o' else 'fa fa-frown-o'
  @accessor 'statusClass', ->
    if (@get('is_up') == true) then 'current-status-container status-up' else 'current-status-container status-down'
  @accessor 'statusText', ->
    if (@get('is_up') == true) then 'Up' else 'Down'