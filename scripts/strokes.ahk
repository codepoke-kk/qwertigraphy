
; nib hops
strokes.item("^") := "m 0,-12"
strokes.item("<") := "m -12,0"
strokes.item("/") := "m 12,0"
strokes.item("\") := "m 0,12"

; vowel holders
strokes.item("i") := ""
strokes.item("a") := ""
strokes.item("e") := ""
strokes.item("o") := ""
strokes.item("u") := 
strokes.item("i2") := ""
strokes.item("a2") := ""
strokes.item("e2") := ""
strokes.item("o2") := ""
strokes.item("u2") := ""

; Consonants
strokes.item("n") := "l 20,0"
strokes.item("m") := "l 36,0"
strokes.item("t") := "l 20,-12"
strokes.item("d") := "l 36,-18"
strokes.item("ng") := "l 15,9"
strokes.item("nk") := "l 36,20"
strokes.item("z") := "l -3,8"
strokes.item("c") := "l -6,20"
strokes.item("j") := "l -8,36"
strokes.item("h") := "m 5,5 c 3,0 0,3 0,0"
strokes.item("H") := "m 0,-15 c 3,0 0,3 0,0 m 0,15"
strokes.item("k") := "c 4,-4 21,-9 20,0"
strokes.item("g") := "c 4,-4 45,-12 36,0"
strokes.item("G") := "m -2,10 c 4,-4 45,-12 36,0"
strokes.item("r") := "c -9,9 11,4 20,0"
strokes.item("l") := "c -9,12 28,4 36,0"
strokes.item("s") := "c -4,0 -9,8 -4,10"
strokes.item("p") := "c -4,0 -20,13 -10,20"
strokes.item("b") := "c -4,0 -36,24 -18,36"
strokes.item("s2") := "c 4,0 4,2 -4,10"
strokes.item("f") := "c 4,0 12,5 -10,20"
strokes.item("v") := "c 4,0 20,8 -18,36"
strokes.item("th") := "c 3,-6 3,-6 18,-12"
strokes.item("th2") := "c 12,-3 17,-4 18,-12"
strokes.item("nd") := "c 8,0 18,0 24,-16"
strokes.item("nt") := strokes.item("nd")
strokes.item("md") := "c 12,0 24,0 36,-20"
strokes.item("mt") := strokes.item("md")
strokes.item("dn") := "c 0,-4 0,-12 24,-16"
strokes.item("tn") := strokes.item("dn")
strokes.item("dm") := "c 0,-2 0,-20 36,-20"
strokes.item("tm") := strokes.item("dm")
strokes.item("dv") := "c -5,-35 60,-55 20,3"
strokes.item("tv") := strokes.item("dv")
strokes.item("df") := strokes.item("dv")
strokes.item("ndv") := "l 15,0 c -5,-35 60,-55 10,3"
strokes.item("ntv") := strokes.item("ndv")
strokes.item("ndf") := strokes.item("ntd")
strokes.item("jnd") := "c -60,55 15,40 20,3"
strokes.item("jnt") := strokes.item("jnd")
strokes.item("pnt") := strokes.item("jnd")
strokes.item("pnd") := strokes.item("jnd")
strokes.item("ld") := "c -9,12 48,8 36,-8"
strokes.item("dt") := "l 42,-21"
strokes.item("td") := strokes.item("dt")
strokes.item("ss") := "c -4,0 -9,6 -4,8 s 1,4 -4,8"
strokes.item("ths") := "c -4,-36 36,-24 18,2"

; A
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
vowelStrokes.item("ja2")  := "c -5,26 26,7 0,0" ;
vowelStrokes.item("la2")  := "c -20,-8 24,-12 0,0" ; 
vowelStrokes.item("ma2")  := "c -6,-22 38,0 0,0" ; 
vowelStrokes.item("da2")  := "c 27,-21 -19,-14 0,0" ;
vowelStrokes.item("tha2")  := "c 18,24 24,-8 0,0" ; 
vowelStrokes.item("a2b")  := "c 18,24 24,-8 0,0" ; 
vowelStrokes.item("da2d")  := "c -30,12 24,-28 0,0" ; 
; I
vowelStrokes.item("iDC")  := vowelStrokes.item("aDC")  " l -6,-6 l 6,6" ; 
vowelStrokes.item("iDK")  := vowelStrokes.item("aDK")  " l 6,-6 l -6,6" ; 
vowelStrokes.item("iFC")  := vowelStrokes.item("aFC")  " l -8,-1 l 8,1" ; 
;vowelStrokes.item("iFD")  := vowelStrokes.item("aFD")  "c 2,-36 24,9 0,2" ; 
vowelStrokes.item("iFK")  := vowelStrokes.item("aFK")  " l 2,-6 l -2,6" ; 
vowelStrokes.item("iLC")  := vowelStrokes.item("aLC")  " l -6,6 l 6,-6"   ; 
vowelStrokes.item("iLK")  := vowelStrokes.item("aLK")  " l -6,-6 l 6,6"   ; 
vowelStrokes.item("iNDC") := vowelStrokes.item("aNDC") " l -8,12 l ,-12" ; 
vowelStrokes.item("iNUC") := vowelStrokes.item("aNUC") " l -9,9 l 9,-9" ; 
vowelStrokes.item("iNUK") := vowelStrokes.item("aNUK") " l 9,-6 l -9,6" ; 
vowelStrokes.item("iUC")  := vowelStrokes.item("aUC")  " l -3,6 l 3,-6"  ; 
vowelStrokes.item("iUK")  := vowelStrokes.item("aUK")  " l -8,0 l 8,0"  ;
; E
vowelStrokes.item("eDC") := "c 2,-12 -12,3 0,2" ; 
vowelStrokes.item("eDK") := "c 4,-12 12,3 0,2" ; 
vowelStrokes.item("eFC") := "c -12,0 0,8 1,2" ; 
vowelStrokes.item("eFD") := "c 2,-12 24,3 0,2" ; 
vowelStrokes.item("eFK") := "c 5,-8 8,8 1,2" ; 
vowelStrokes.item("eLC") := "c -12,4 3,9 2,0"   ; 
vowelStrokes.item("eLK") := "c -12,-4 3,-9 2,0"   ; 
vowelStrokes.item("eNDC") := "c -12,9 0,12 0,2" ; 
vowelStrokes.item("eNUC") := "c -16,10 -5,10 0,2" ; 
vowelStrokes.item("eNUK") := "c 0,-12 12,-6 0,-2" ; 
vowelStrokes.item("eUC") := "c -14,5 16,5 2,-1"  ; 
vowelStrokes.item("eUK") := "c -14,-5 2,-7 2,-1"  ;
; O
vowelStrokes.item("oP") := "c 0,8 6,8 6,0" ; 
vowelStrokes.item("oS") := "c -8,0 -8,6 0,6" ; 
; U
vowelStrokes.item("uB") := "c 0,-8 6,-8 6,0" ; 
vowelStrokes.item("uT") := "c 8,0 8,6 0,6" ; 
