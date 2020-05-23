#Hotstring EndChars -()[]{}:'"/\,.?!`n `t" 
^j::
	Suspend toggle
    Return

^Space::
	Suspend toggle
	Suspend toggle
    Send {Space}
    Return
^.::
	Suspend toggle
	Suspend toggle
    Send {.}
    Return
^,::
	Suspend toggle
	Suspend toggle
    Send {,}
    Return
+^;::
	Suspend toggle
	Suspend toggle
    Send {:}
    Return
^Tab::
	Suspend toggle
	Suspend toggle
    Send {Tab}
    Return
^Enter::
	Suspend toggle
	Suspend toggle
    Send {Enter}
    Return


:?:'s::'s 
:?:'d::'d
:?:'t::'t
:?:'m::'m
:?:'re::'re
:?:'ve::'ve
:C:s::is
:C:d::would
:C:t::it
:C:m::am
:C:re::real
:C:ve::very
:C:S::Is
:C:D::Would
:C:T::It
:C:M::Am
:C:Re::Real
:C:Ve::Very

:C:TH::There
:C:hhs::thinks
:C:Hhs::Thinks
:C:hhs2::things
:C:Hhs2::Things
:C:mit::might
:C:Mit::Might
:C:lif::life
:C:Lif::Life

CoordMode Caret

::clearahklog::
    FileDelete Qwertigraphy.log
    FileAppend New log started now!`n, Qwertigraphy.log
    Return

FlashTip(tip) {
    Tooltip %tip%, A_CaretX, A_CaretY + 30
    Sleep 1500
    ToolTip
    FileAppend %tip% `n, Qwertigraphy.log 
    Return
}
CoachOutline(word, outline, savings, power) {
    MsgBox % outline 
}