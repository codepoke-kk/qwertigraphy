#$path = "M100,191 C207,62 218,332 100,191"

# https://codepen.io/explosion/full/YGApwd
$path = Read-Host "Unscaled curve: "
$empty1, $startX, $startY, $empty2, $anchor1X, $anchor1Y, $anchor2X, $anchor2Y, $moveX, $moveY = `
    $path -split '[m,c ]'

$scaleFactor = .15
$startX   =  [int]$startX  
$startY   =  [int]$startY  
$anchor1X =  [int](([int]$anchor1X - $startX) * $scaleFactor)
$anchor1Y =  [int](([int]$anchor1Y - $startY) * $scaleFactor)
$anchor2X =  [int](([int]$anchor2X - $startX) * $scaleFactor)
$anchor2Y =  [int](([int]$anchor2Y - $startY) * $scaleFactor)
$moveX    =  [int](([int]$moveX - $startX   ) * $scaleFactor)
$moveY    =  [int](([int]$moveY - $startY   ) * $scaleFactor)


"c $anchor1X,$anchor1Y $anchor2X,$anchor2Y $moveX,$moveY"
