$vowelShapes = @'
vowelStrokes.item("ba")  := "c 16,-19 18,21 0,0" ;
vowelStrokes.item("va")  := "c -31,-10 -20,22 0,0" ;
vowelStrokes.item("vab")  := vowelStrokes.item("va")
vowelStrokes.item("vav")  := vowelStrokes.item("va")
vowelStrokes.item("ga")  := "c -3,23 -34,1 0,0" ;
vowelStrokes.item("ja")  := "c -5,26 -28,-1 0,0" ;
vowelStrokes.item("la")  := "c -20,-8 24,-12 0,0" ; 
vowelStrokes.item("ma")  := "c -18,16 30,0 0,0" ; 
vowelStrokes.item("da")  := "c 27,-21 9,21 0,0" ;
vowelStrokes.item("tha")  := "c 18,24 24,-8 0,0" ; 							
vowelStrokes.item("ab")  := "c 18,24 24,-8 0,0" ; 
vowelStrokes.item("dad")  := "c -16,28 30,-12 0,0" ; 	 
vowelStrokes.item("ba2")  := "c -29,21 2,14 0,0" ;			
vowelStrokes.item("va2")  := "c -22,16 16,17 0,0" ;
vowelStrokes.item("va2b")  := vowelStrokes.item("va")
vowelStrokes.item("va2v")  := vowelStrokes.item("va")
vowelStrokes.item("ga2")  := "c -12,-12 -26,17 0,0" ;
vowelStrokes.item("ja2")  := "c -9,27 37,3 0,0" ;
vowelStrokes.item("la2")  := "c 13,16 32,-17 0,0" ; 
vowelStrokes.item("ma2")  := "c -6,-22 38,0 0,0" ; 
vowelStrokes.item("da2")  := "c 27,-21 -19,-14 0,0" ;
vowelStrokes.item("tha2")  := "c 18,24 24,-8 0,0" ; 
vowelStrokes.item("a2b")  := "c 18,24 24,-8 0,0" ; 
vowelStrokes.item("da2d")  := "c -30,12 24,-28 0,0" ; 
'@


$eScaleFactor = .45

$vowelLines = @($vowelShapes -split "`n")

function ConvertTo-EForm {
    param (
        [int]$anchor1X,
        [int]$anchor1Y,
        [int]$anchor2X,
        [int]$anchor2Y,
        [int]$moveX,
        [int]$moveY
    )

    return "c $([int]($anchor1X * $eScaleFactor)),$([int]($anchor1Y * $eScaleFactor)) $([int]($anchor2X * $eScaleFactor)),$([int]($anchor2Y * $eScaleFactor)) $moveX,$moveY"

}

function ConvertTo-INub {
    param (
        [int]$anchor1X,
        [int]$anchor1Y,
        [int]$anchor2X,
        [int]$anchor2Y,
        [int]$moveX,
        [int]$moveY
    )
    
    $x = ($anchor1X + $anchor2X) / 2
    $y = ($anchor1Y + $anchor2Y) / 2
    return "c $([int]($x * $eScaleFactor)),$([int]($y * $eScaleFactor)) $([int]($x * $eScaleFactor)),$([int]($y * $eScaleFactor)) $moveX,$moveY"

}

foreach ($vowelLine in $vowelLines) {
    # Break the ingested line up to separate out the path
    ($variable, $key, $center, $path, $ending) = $vowelLine -split '"', 5

    # "$variable|$key|$center|$path|$ending"
    # Break the path up to create numbers
    ($c, $anchor1X, $anchor1Y, $anchor2X, $anchor2Y, $moveX, $moveY) = $path -split '[, ]'
    
    if ($path.StartsWith('c ')) {
        $eForm = ConvertTo-EForm -anchor1X $anchor1X -anchor1Y $anchor1Y -anchor2X $anchor2X -anchor2Y $anchor2Y -moveX $moveX -moveY $moveY
        $iForm = ConvertTo-INub -anchor1X $anchor1X -anchor1Y $anchor1Y -anchor2X $anchor2X -anchor2Y $anchor2Y -moveX $moveX -moveY $moveY
        
        # Output E's
        $ekey = $key -replace 'a', 'e'
        "$variable`"$ekey`"$center`"$eForm`"$ending"


        # Output EA's 
        $eakey = $key -replace 'a', 'ea'
        "$variable`"$eakey`"$center`"$eForm $path`"$ending"

        # Output I's
        $ikey = $key -replace 'a', 'i'
        "$variable`"$ikey`"$center`"$iForm $path`"$ending"
    } else {
        # These are clones 
        "$variable`"$key`"$center`"$path`"$ending"
        # Output E's
        $ekey = $key -replace 'a', 'e'
        $epath = $path -replace 'a', 'e'
        "$variable`"$ekey`"$center`"$epath`"$ending"

        # Output EA's 
        $eakey = $key -replace 'a', 'ea'
        $eapath = $path -replace 'a', 'ea'
        "$variable`"$eakey`"$center`"$eapath`"$ending"

        # Output I's
        $ikey = $key -replace 'a', 'i'
        $ipath = $path -replace 'a', 'i'
        "$variable`"$ikey`"$center`"$ipath`"$ending"
    }

}
return

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
