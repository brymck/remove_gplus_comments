# Remove Google+ comments on initial comment load
$(".pga .Yp:contains(via Google+)").remove()

# Remove Google+ comments after clicking Show More
$(".pga").on "DOMNodeInserted", (e) ->
  $target = $(e.target)
  if $target.text().indexOf("via Google+") isnt -1
    $target.remove()
