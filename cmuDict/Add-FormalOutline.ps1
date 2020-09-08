Function Add-FormalOutline {
    #[CmdletBinding()]
    Param (
         [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$cmu
    )
    Begin{
        Write-Host ("Adding Formal Gregg Outline to CMU Line")
        $afoProgressIndex = 0
        $afoStartTime = Get-Date
    }
    Process {
        $word,$pronunciation = $cmu -split ','
        Write-Verbose ("Converting $pronunciation for $word")
        $formalOutline = ConvertTo-FormalGreggOutline -word $word -pronunciation $pronunciation 
        if ($formalOutline.length -gt 0) {
            "$cmu,$($formalOutline.trim())"
        } else {
            Write-Host ("Failed to add meaningful outline for $word")
        }
    }
    End{
        Write-Host ("Done Adding Formal Gregg Outlines to CMU Line after $((New-TimeSpan -Start $afoStartTime -End (Get-Date)).TotalSeconds) seconds")
    }
}


Function ConvertTo-FormalGreggOutline {
    param (
        $word,
        $pronunciation
    )
 
    # Whole words
    $pronunciation = $pronunciation -creplace 'K AH0 M Y UW2 N AH0 K EY1 SH AH0 N ?\b', 'kmnu'	#communication is not kY UW2 nukaz
    $pronunciation = $pronunciation -creplace 'K AO2 R AH0 S P AA1 N D AH0 N S ?\b', 'kres'	#correspondence is not kspondns
    $pronunciation = $pronunciation -creplace 'IH2 N D AH0 V IH1 JH AH0 W AH0 L ?\b', 'ndv'	#individual is not nduvejuuul
    $pronunciation = $pronunciation -creplace 'R IH0 S P EH1 K T F AH0 L IY0 ?\b', 'res'	#respectfully is not respektfle
    $pronunciation = $pronunciation -creplace 'S AE2 T AH0 S F AE1 K T R IY0 ?\b', 'sat'	#satisfactory is not satsfaktre
    $pronunciation = $pronunciation -creplace 'AO2 R G AH0 N AH0 Z EY1 SH AH0 N ?\b', 'og'	#organization is not argnsaz
    $pronunciation = $pronunciation -creplace 'K AH0 N S IH2 D ER0 EY1 SH AH0 N ?\b', 'ks'	#consideration is not ksdraz
    $pronunciation = $pronunciation -creplace 'R IY0 S P AA1 N S AH0 B AH0 L ?\b', 'rsp'	#responsible is not responsbl
    $pronunciation = $pronunciation -creplace 'K AH0 M Y UW1 N AH0 K EY2 T ?\b', 'kmnu'	#communicate is not keunukat
    $pronunciation = $pronunciation -creplace 'AA2 P ER0 T UW1 N AH0 T IY0 ?\b', 'opr'	#opportunity is not oprtunute
    $pronunciation = $pronunciation -creplace 'AH0 P R AA1 K S AH0 M AH0 T ?\b', 'aprx'	#approximate is not aproxmt
    $pronunciation = $pronunciation -creplace 'P ER0 T IH1 K Y AH0 L ER0 ?\b', 'pat'	#particular is not prtekY ulr
    $pronunciation = $pronunciation -creplace 'IH0 K S P IH1 R IY0 AH0 N S ?\b', 'spe'	#experience is not esperens
    $pronunciation = $pronunciation -creplace 'IH2 M IY1 D IY2 AH0 T L IY0 ?\b', 'eme'	#immediately is not medetle
    $pronunciation = $pronunciation -creplace 'N EH2 V ER0 DH AH0 L EH1 S ?\b', 'nvl'	#nevertheless is not nvrHles
    $pronunciation = $pronunciation -creplace 'D IH1 F AH0 K AH0 L T IY0 ?\b', 'dfk'	#difficulty is not defukulte
    $pronunciation = $pronunciation -creplace 'AH0 K W EY1 N T AH0 N S ?\b', 'aka'	#acquaintance is not aqantuns
    $pronunciation = $pronunciation -creplace 'M ER1 CH AH0 N D AY2 Z ?\b', 'mecdis'	#merchandise is not mrzdis
    $pronunciation = $pronunciation -creplace 'ER0 EY1 N JH M AH0 N T ?\b', 'ara'	#arrangement is not aranjmnt
    $pronunciation = $pronunciation -creplace 'IH2 M P R UW1 V M AH0 N T ?\b', 'mpr'	#improvement is not mprvm
    $pronunciation = $pronunciation -creplace 'K AA1 M P L AH0 M EH0 N T ?\b', 'kplem'	#compliment is not kplm
    $pronunciation = $pronunciation -creplace 'K AO2 R AH0 S P AA1 N D ?\b', 'kres'	#correspond is not kspond
    $pronunciation = $pronunciation -creplace 'F EH1 B Y AH0 W EH2 R IY0 ?\b', 'feb'	#february is not febuure
    $pronunciation = $pronunciation -creplace 'AE0 K S EH1 P T AH0 N S ?\b', 'aks'	#acceptance is not axeptns
    $pronunciation = $pronunciation -creplace 'K AA1 R P AH0 N T ER0 ?\b', 'krpntr'	#carpenter is not krpntE
    $pronunciation = $pronunciation -creplace 'IH2 M P AO1 R T AH0 N S ?\b', 'mp'	#importance is not mportns
    $pronunciation = $pronunciation -creplace 'IH\d M P AO1 R T AH0 N T ?\b', 'mp'	#important is not mportnt
    $pronunciation = $pronunciation -creplace 'G AH1 V ER0 N M AH0 N T ?\b', 'gv'	#government is not gvrnmnt
    $pronunciation = $pronunciation -creplace 'AO2 L T AH0 G EH1 DH ER0 ?\b', 'otu'	#altogether is not altug
    $pronunciation = $pronunciation -creplace 'M IH1 Z ER0 AH0 B AH0 L ?\b', 'mserb'	#miserable is not mesrb
    $pronunciation = $pronunciation -creplace 'K AH0 N V EH1 N SH AH0 N ?\b', 'kvz'	#convention is not kvenz
    $pronunciation = $pronunciation -creplace 'R EH2 P R AH0 Z EH1 N T ?\b', 'rp'	#represent is not rprsent
    $pronunciation = $pronunciation -creplace 'D IH1 F AH0 K AH0 L T ?\b', 'dfk'	#difficult is not defukult
    $pronunciation = $pronunciation -creplace 'EH2 JH AH0 K EY1 SH AH0 N ?\b', 'edu'	#education is not jkaz
    $pronunciation = $pronunciation -creplace 'S AH0 JH EH1 S CH AH0 N ?\b', 'suj'	#suggestion is not sjesz
    $pronunciation = $pronunciation -creplace 'R IY0 M IH1 T AH0 N S ?\b', 'rem'	#remittance is not remetns
    $pronunciation = $pronunciation -creplace 'G OW1 L D ?\b', 'gold'	#gold is not gld, even though go is g
    $pronunciation = $pronunciation -creplace 'AE0 D V AE1 N T IH0 JH ?\b', 'av'	#advantage is not advantj
    $pronunciation = $pronunciation -creplace 'K AA1 N F AH0 D EH0 N S ?\b', 'kf'	#confidence is not kfdns
    $pronunciation = $pronunciation -creplace 'S EH0 P T EH1 M B ER0 ?\b', 'sep'	#september is not sptembr
    $pronunciation = $pronunciation -creplace 'JH AE1 N Y UW0 EH2 R IY0 ?\b', 'jan'	#january is not janure
    $pronunciation = $pronunciation -creplace 'S AH0 F IH1 SH AH0 N T ?\b', 'suf'	#sufficient is not sfezt
    $pronunciation = $pronunciation -creplace 'R IH0 L AY1 AH0 B AH0 L ?\b', 'relib'	#reliable is not rlib
    $pronunciation = $pronunciation -creplace 'Y EH1 S T ER0 D EY2 ?\b', 'est'	#yesterday is not Y estrda
    $pronunciation = $pronunciation -creplace 'EH1 K S AH0 L AH0 N S ?\b', 'esl'	#excellence is not exlns
    $pronunciation = $pronunciation -creplace 'K AE1 T AH0 L AO2 G ?\b', 'katl'	#catalogue is not katulog
    $pronunciation = $pronunciation -creplace 'IH1 N D AH0 S T R IY0 ?\b', 'nds'	#industry is not ndustre
    $pronunciation = $pronunciation -creplace 'IH1 N F L UW0 AH0 N S ?\b', 'nf'	#influence is not nfluuns
    $pronunciation = $pronunciation -creplace 'AE0 K N AA1 L IH0 JH ?\b', 'ak'	#acknowledge is not aknolj
    $pronunciation = $pronunciation -creplace 'K AA1 N F AH0 D AH0 N T ?\b', 'kf'	#confident is not kfdnt
    $pronunciation = $pronunciation -creplace 'IH2 N SH UH1 R AH0 N S ?\b', 'nz'	#insurance is not nzuuns
    $pronunciation = $pronunciation -creplace 'P R IY1 V IY0 AH0 S ?\b', 'prevs'	#previous is not preveas
    $pronunciation = $pronunciation -creplace 'K W AA1 N T AH0 T IY0 ?\b', 'kT'	#quantity is not kontute
    $pronunciation = $pronunciation -creplace 'EH1 K S AH0 L AH0 N T ?\b', 'esl'	#excellent is not exlnt
    $pronunciation = $pronunciation -creplace 'M IH0 S T EY1 K AH0 N ?\b', 'mst'	#mistaken is not mstakn
    $pronunciation = $pronunciation -creplace 'M IH1 N AH0 S T ER0 ?\b', 'mnestE'	#minister is not mnstr
    $pronunciation = $pronunciation -creplace 'N UW1 Z P EY2 P ER0 ?\b', 'nsp'	#newspaper is not nuspapr
    $pronunciation = $pronunciation -creplace 'IH2 M IY1 D IY2 AH0 T ?\b', 'eme'	#immediate is not medet
    $pronunciation = $pronunciation -creplace 'HH EY1 S T AH0 L IY0 ?\b', 'hasty'	#hastily is not hastle
    $pronunciation = $pronunciation -creplace 'F AE1 M AH0 L IY0 Z ?\b', 'famys'	#families is not famles
    $pronunciation = $pronunciation -creplace 'AE1 D V ER0 T AY2 Z ?\b', 'avt'	#advertise is not advrtis
    $pronunciation = $pronunciation -creplace 'P R IH0 V EH1 N T ?\b', 'prevent'	#prevent is not prevnt
    $pronunciation = $pronunciation -creplace 'HH AA1 R T AH0 L IY0 ?\b', 'hAty'	#heartily is not hAtle
    $pronunciation = $pronunciation -creplace 'D IH0 L IH1 V ER0 IY0 ?\b', 'dl'	#delivery is not dlevre
    $pronunciation = $pronunciation -creplace 'Y UW1 ZH AH0 W AH0 L ?\b', 'uz'	#usual is not Y uZH uuul
    $pronunciation = $pronunciation -creplace 'AH0 T EH1 N SH AH0 N ?\b', 'tnz'	#attention is not atenz
    $pronunciation = $pronunciation -creplace 'D IH0 S EH1 M B ER0 ?\b', 'des'	#december is not dsembr
    $pronunciation = $pronunciation -creplace 'EH1 M F AH0 S IH0 S ?\b', 'mfass'	#emphasis is not mfss
    $pronunciation = $pronunciation -creplace 'N OW0 V EH1 M B ER0 ?\b', 'nv'	#november is not novembr
    $pronunciation = $pronunciation -creplace 'T IY1 D IY0 AH0 S ?\b', 'tedus'	#tedious is not tedeas 
    $pronunciation = $pronunciation -creplace 'K AH0 M P L EY1 N T ?\b', 'kP'	#complaint is not kplant
    $pronunciation = $pronunciation -creplace 'V AE1 L Y AH0 B AH0 L ?\b', 'vlb'	#valuable is not valb
    $pronunciation = $pronunciation -creplace 'P R AA1 B AH0 B AH0 L ?\b', 'prb'	#probable is not prbb
    $pronunciation = $pronunciation -creplace 'R IH0 M EH1 M B ER0 ?\b', 'rem'	#remember is not remnbr
    $pronunciation = $pronunciation -creplace 'D AH0 T ER1 M AH0 N ?\b', 'emn'	#determine is not dtrmn
    $pronunciation = $pronunciation -creplace 'D IH1 F ER0 AH0 N S ?\b', 'df'	#difference is not defns
    $pronunciation = $pronunciation -creplace 'D EH1 F AH0 S AH0 T ?\b', 'dfeset'	#deficit is not dfst
    $pronunciation = $pronunciation -creplace 'AO0 L R EH1 D IY0 ?\b', 'ore'	#already is not AO0 lrede
    $pronunciation = $pronunciation -creplace 'K EH1 R IH0 K T ER0 ?\b', 'kak'	#character is not kaktE
    $pronunciation = $pronunciation -creplace 'CH IH1 L D R AH0 N ?\b', 'cel'	#children is not celdrn
    $pronunciation = $pronunciation -creplace 'P AH0 Z IH1 SH AH0 N ?\b', 'poz'	#position is not psez
    $pronunciation = $pronunciation -creplace 'D IH1 F ER0 AH0 N T ?\b', 'df'	#different is not defnt
    $pronunciation = $pronunciation -creplace 'K AW1 N S AH0 L ?\b', 'ksel'	#council is not kAW1 nsul
    $pronunciation = $pronunciation -creplace 'R EH1 G Y AH0 L ER0 ?\b', 'reg'	#regular is not regulr
    $pronunciation = $pronunciation -creplace 'AA1 R JH UW0 AH0 S ?\b', 'Aduus'	#arduous is not Ajuus
    $pronunciation = $pronunciation -creplace 'R IH0 S P AA1 N S ?\b', 'rsp'	#response is not respons
    $pronunciation = $pronunciation -creplace 'K W EH1 S CH AH0 N ?\b', 'kz'	#question is not kuescun
    $pronunciation = $pronunciation -creplace 'S OW1 SH AH0 L IY0 ?\b', 'sozy'	#socially is not sozle
    $pronunciation = $pronunciation -creplace 'R EH1 F ER0 AH0 N S ?\b', 'rf'	#reference is not refns
    $pronunciation = $pronunciation -creplace 'EH1 N V AH0 L OW2 P ?\b', 'nvl'	#envelope is not nvlop
    $pronunciation = $pronunciation -creplace 'K AE1 T AH0 L AO0 G ?\b', 'katl'	#catalog is not katlg
    $pronunciation = $pronunciation -creplace 'IH0 K S P EH1 N S ?\b', 'espns'	#expense is not espens
    $pronunciation = $pronunciation -creplace 'S AE1 T AH0 S F AY2 ?\b', 'sat'	#satisfy is not satsfi
    $pronunciation = $pronunciation -creplace 'AH0 P IH1 N Y AH0 N ?\b', 'opn'	#opinion is not apnY n
    $pronunciation = $pronunciation -creplace 'F AO1 R M AH0 L IY0 ?\b', 'fmly'	#formally is not fmle
    $pronunciation = $pronunciation -creplace 'P ER1 S IH0 N AH0 L ?\b', 'prs'	#personal is not prsnl
    $pronunciation = $pronunciation -creplace 'B AE1 NG K W AH0 T ?\b', 'baqet'	#banquet is not baqut
    $pronunciation = $pronunciation -creplace 'AO1 R G AH0 N AY2 Z ?\b', 'og'	#organize is not orgniz
    $pronunciation = $pronunciation -creplace 'TH R UW0 AW1 T ?\b', 'hrut'	#throughout is not Hruaot
    $pronunciation = $pronunciation -creplace 'IH0 K S P L EY1 N ?\b', 'espl'	#explain is not explan
    $pronunciation = $pronunciation -creplace 'IH0 K S P R EH1 S ?\b', 'espr'	#express is not expres
    $pronunciation = $pronunciation -creplace 'P R AA1 G R EH2 S ?\b', 'prg'	#progress is not progrs
    $pronunciation = $pronunciation -creplace 'S T R EH1 NG K TH ?\b', 'str'	#strength is not streqh
    $pronunciation = $pronunciation -creplace 'HH AH1 N D R AH0 D ?\b', 'hund'	#hundred is not hndrd
    $pronunciation = $pronunciation -creplace 'K AH0 N S IH1 D ER0 ?\b', 'ks'	#consider is not ksedE
    $pronunciation = $pronunciation -creplace 'K AH0 N V IH1 N S ?\b', 'kvens'	#convince is not kvns
    $pronunciation = $pronunciation -creplace 'T EH1 R AH0 B AH0 L ?\b', 'terb'	#terrible is not tEb
    $pronunciation = $pronunciation -creplace 'F R EH1 N D L IY0 ?\b', 'fr'	#friendly is not frendle
    $pronunciation = $pronunciation -creplace 'TH AW1 Z AH0 N D ?\b', 'hau'	#thousand is not haosund
    $pronunciation = $pronunciation -creplace 'AH0 F IH1 SH AH0 L ?\b', 'ofl'	#official is not afezl
    $pronunciation = $pronunciation -creplace 'P ER0 HH AE1 P S ?\b', 'praps'	#perhaps is not prhaps
    $pronunciation = $pronunciation -creplace 'K AE1 P IH0 T AH0 L ?\b', 'kpt'	#capital is not kaptl
    $pronunciation = $pronunciation -creplace 'T AH0 G EH1 DH ER0 ?\b', 'tug'	#together is not tgehr
    $pronunciation = $pronunciation -creplace 'S AH0 B JH EH1 K T ?\b', 'sj'	#subject is not subjekt
    $pronunciation = $pronunciation -creplace 'AH0 S P EH1 SH AH0 L ?\b', 'esp'	#especial is not asp
    $pronunciation = $pronunciation -creplace 'R IH0 S P EH1 K T ?\b', 'res'	#respect is not respekt
    $pronunciation = $pronunciation -creplace 'S AE1 T ER0 D IY0 ?\b', 'sat'	#saturday is not satrde
    $pronunciation = $pronunciation -creplace 'S IH1 R IY0 AH0 S ?\b', 'sers'	#serious is not sereas
    $pronunciation = $pronunciation -creplace 'D EH1 F AH0 N AH0 T ?\b', 'dfn'	#definite is not dfnt
    $pronunciation = $pronunciation -creplace 'K W AA1 L AH0 T IY0 ?\b', 'ku'	#quality is not qolute
    $pronunciation = $pronunciation -creplace 'EH1 K W AH0 T IY0 ?\b', 'eqete'	#equity is not equte
    $pronunciation = $pronunciation -creplace 'EH1 L AH0 M AH0 N T ?\b', 'elem'	#element is not elm
    $pronunciation = $pronunciation -creplace 'R EH1 D AH0 L IY0 ?\b', 'redy'	#readily is not redle
    $pronunciation = $pronunciation -creplace 'N OW1 T IH0 S T ?\b', 'notest'	#noticed is not notsd
    $pronunciation = $pronunciation -creplace 'K AA1 M R AE2 D ?\b', 'kmrad'	#comrade is not kamrad
    $pronunciation = $pronunciation -creplace 'T OW1 T AH0 L IY0 ?\b', 'toty'	#totally is not totle
    $pronunciation = $pronunciation -creplace 'R IY1 AH0 L AY2 Z ?\b', 'reliz'	#realize is not rliz
    $pronunciation = $pronunciation -creplace 'AH0 K EY1 ZH AH0 N ?\b', 'kaz'	#occasion is not okaz
    $pronunciation = $pronunciation -creplace 'T AH0 M AA1 R OW2 ?\b', 'tmo'	#tomorrow is not tmoro
    $pronunciation = $pronunciation -creplace 'HH AE1 P AH0 N D ?\b', 'hapnd'	#happened is not hapd
    $pronunciation = $pronunciation -creplace 'P R EH1 Z AH0 N S ?\b', 'pr'	#presence is not presns
    $pronunciation = $pronunciation -creplace 'IH0 N D EH1 V ER0 ?\b', 'ndvr'	#endeavor is not ndev
    $pronunciation = $pronunciation -creplace 'P R AA1 B L AH0 M ?\b', 'prbl'	#problem is not prblm
    $pronunciation = $pronunciation -creplace 'AA0 K T OW1 B ER0 ?\b', 'okt'	#october is not oktobr
    $pronunciation = $pronunciation -creplace 'K AH1 M P AH0 N IY2 ?\b', 'kp'	#company is not kmpne
    $pronunciation = $pronunciation -creplace 'W EH1 N Z D IY0 ?\b', 'uens'	#wednesday is not ensde
    $pronunciation = $pronunciation -creplace 'EH1 JH AH0 K EY2 T ?\b', 'edu'	#educate is not ejkat
    $pronunciation = $pronunciation -creplace 'R IH0 N UW1 AH0 L ?\b', 'renul'	#renewal is not rnul
    $pronunciation = $pronunciation -creplace 'IH1 N S T AH0 N S ?\b', 'ns'	#instance is not nstns
    $pronunciation = $pronunciation -creplace 'P R IY0 P EH1 R ?\b', 'prep'	#prepare is not prepar
    $pronunciation = $pronunciation -creplace 'F AE1 M AH0 L IY0 ?\b', 'famy'	#family is not famle
    $pronunciation = $pronunciation -creplace 'HH Y UW1 M AH0 N ?\b', 'heumn'	#human is not heumun
    $pronunciation = $pronunciation -creplace 'R IY2 K W AY1 ER0 ?\b', 'rki'	#require is not reqir
    $pronunciation = $pronunciation -creplace 'IH0 K S P EH1 K T ?\b', 'esp'	#expect is not expekt
    $pronunciation = $pronunciation -creplace 'EH0 M P L OY1 ?\b', 'mpl'	#employ is not EH0 mplOY1
    $pronunciation = $pronunciation -creplace 'K AH0 M P L EY1 N ?\b', 'kP'	#complain is not kplan
    $pronunciation = $pronunciation -creplace 'V EH1 R IY0 AH0 S ?\b', 'vars'	#various is not veus
    $pronunciation = $pronunciation -creplace 'K AH0 M P L IY1 T ?\b', 'kP'	#complete is not kplet
    $pronunciation = $pronunciation -creplace 'K AA1 M AH0 D IY0 ?\b', 'kmede'	#comedy is not kde
    $pronunciation = $pronunciation -creplace 'P R IH0 Z UW1 M ?\b', 'prsm'	#presume is not presm
    $pronunciation = $pronunciation -creplace 'S AH0 JH EH1 S T ?\b', 'suj'	#suggest is not sjest
    $pronunciation = $pronunciation -creplace 'HH AA1 R D L IY0 ?\b', 'hAde'	#hardly is not hAdle
    $pronunciation = $pronunciation -creplace 'F Y UW1 CH ER0 ?\b', 'ft'	#future is not fY UW1 cr
    $pronunciation = $pronunciation -creplace 'IH1 N S T AH0 N T ?\b', 'ns'	#instant is not nstnt
    $pronunciation = $pronunciation -creplace 'P R AA1 M AH0 S ?\b', 'prmes'	#promise is not prms
    $pronunciation = $pronunciation -creplace 'IH2 N S P EH1 K T ?\b', 'nsp'	#inspect is not nspk
    $pronunciation = $pronunciation -creplace 'AH0 K W EY1 N T ?\b', 'aka'	#acquaint is not aqant
    $pronunciation = $pronunciation -creplace 'D IH0 L IH1 V ER0 ?\b', 'dl'	#deliver is not dlevr
    $pronunciation = $pronunciation -creplace 'L AH1 N CH AH0 N ?\b', 'lncn'	#luncheon is not lnz
    $pronunciation = $pronunciation -creplace 'M IH1 Z ER0 IY0 ?\b', 'msere'	#misery is not msre
    $pronunciation = $pronunciation -creplace 'R IY0 P AO1 R T ?\b', 'rpr'	#report is not report
    $pronunciation = $pronunciation -creplace 'IH0 N K L OW1 Z ?\b', 'nk'	#enclose is not enklos
    $pronunciation = $pronunciation -creplace 'P ER1 CH AH0 S ?\b', 'prc'	#purchase is not prcus
    $pronunciation = $pronunciation -creplace 'AO2 L DH OW1 ?\b', 'aHo'	#although is not AO2 lho
    $pronunciation = $pronunciation -creplace 'TH ER1 Z D EY2 ?\b', 'hrs'	#thursday is not hrsda
    $pronunciation = $pronunciation -creplace 'M IH0 S T EY1 K ?\b', 'mst'	#mistake is not mstak
    $pronunciation = $pronunciation -creplace 'AH0 K AW1 N T ?\b', 'akt'	#accountable needs an a
    $pronunciation = $pronunciation -creplace 'K AW1 N T IY0 ?\b', 'kte'	#county is not kAW1 nte
    $pronunciation = $pronunciation -creplace 'S T R EY1 N JH ?\b', 'stj'	#strange is not stranj
    $pronunciation = $pronunciation -creplace 'N AA1 L AH0 JH ?\b', 'nol'	#knowledge is not nolj
    $pronunciation = $pronunciation -creplace 'K AH0 L EH1 K T ?\b', 'kol'	#collect is not klekt
    $pronunciation = $pronunciation -creplace 'M Y UW1 Z IH0 K ?\b', 'musek'	#music is not meusk
    $pronunciation = $pronunciation -creplace 'S P EH1 SH AH0 L ?\b', 'sp'	#special is not spezl
    $pronunciation = $pronunciation -creplace 'R IH0 P EH1 N T ?\b', 'rpnt'	#repent is not rpent
    $pronunciation = $pronunciation -creplace 'IH0 K S EH1 P T ?\b', 'sep'	#except is not esept
    $pronunciation = $pronunciation -creplace 'R IH0 M AA1 R K ?\b', 'rm'	#remark is not remork
    $pronunciation = $pronunciation -creplace 'IH2 N K W AY1 R ?\b', 'nki'	#inquire is not nqir
    $pronunciation = $pronunciation -creplace 'K R EH1 D AH0 T ?\b', 'kre'	#credit is not kredt
    $pronunciation = $pronunciation -creplace 'IH2 M P R UW1 V ?\b', 'mpr'	#improve is not mprv
    $pronunciation = $pronunciation -creplace 'R AH0 G R EH1 T ?\b', 'reg'	#regret is not rgret
    $pronunciation = $pronunciation -creplace 'T R AH1 B AH0 L ?\b', 'trb'	#trouble is not trub
    $pronunciation = $pronunciation -creplace 'W IH0 TH AW1 T ?\b', 'eht'	#without is not uhaot
    $pronunciation = $pronunciation -creplace 'K AH0 M P L AY1 ?\b', 'kpli'	#Comply doesn't kPi
    $pronunciation = $pronunciation -creplace 'AE0 K S EH1 P T ?\b', 'aks'	#accept is not axept
    $pronunciation = $pronunciation -creplace 'AA1 B JH EH0 K T ?\b', 'ob'	#object is not objkt
    $pronunciation = $pronunciation -creplace 'P ER0 F EH1 K T ?\b', 'prf'	#perfect is not prfk
    $pronunciation = $pronunciation -creplace 'S P IH1 R AH0 T ?\b', 'spr'	#spirit is not spert
    $pronunciation = $pronunciation -creplace 'B IH0 HH AY1 N D ?\b', 'bi'	#behind is not bhind
    $pronunciation = $pronunciation -creplace 'S AH1 L AH0 N ?\b', 'sulen'	#sullen is not sulun
    $pronunciation = $pronunciation -creplace 'M AE1 N ER0 Z ?\b', 'mnEs'	#manners is not manrs
    $pronunciation = $pronunciation -creplace 'M OW1 M AH0 N T ?\b', 'mom'	#moment is not mnent
    $pronunciation = $pronunciation -creplace 'R IH0 S IY1 T ?\b', 'rese'	#receipt is not reset
    $pronunciation = $pronunciation -creplace 'S AH0 K S EH1 S ?\b', 'suk'	#success is not sxes
    $pronunciation = $pronunciation -creplace 'G R EY1 T ER0 ?\b', 'grr'	#greater is not gratr
    $pronunciation = $pronunciation -creplace 'IH0 N T AY1 ER0 ?\b', 'nti'	#entire is not enti
    $pronunciation = $pronunciation -creplace 'R IY1 S AH0 N T ?\b', 'rs'	#recent is not resnt
    $pronunciation = $pronunciation -creplace 'AH0 N EY1 B AH0 L ?\b', 'nb'	#unable is not anb
    $pronunciation = $pronunciation -creplace 'R IH0 M EY1 N ?\b', 'remn'	#remain is not reman
    $pronunciation = $pronunciation -creplace 'S AH0 P OW1 Z ?\b', 'spo'	#suppose is not supos
    $pronunciation = $pronunciation -creplace 'K AH0 M P EH1 L ?\b', 'kpl'	#compel is not kpel
    $pronunciation = $pronunciation -creplace 'AH0 K R AO1 S ?\b', 'akrs'	#across is not akros
    $pronunciation = $pronunciation -creplace 'EH0 N EY1 B AH0 L ?\b', 'enb'	#enable is not nb
    $pronunciation = $pronunciation -creplace 'S IH1 S T ER0 ?\b', 'sstE'	#sister is not sestr
    $pronunciation = $pronunciation -creplace 'S EY1 F L IY0 ?\b', 'safe'	#safely is not safle
    $pronunciation = $pronunciation -creplace 'S AH0 P L AY1 ?\b', 'spli'	#supply is not supli
    $pronunciation = $pronunciation -creplace 'L EY1 T L IY0 ?\b', 'late'	#lately is not latle
    $pronunciation = $pronunciation -creplace 'AH0 P OY1 N T ?\b', 'oe'	#appoint is not apoent
    $pronunciation = $pronunciation -creplace 'R AH0 K AO1 R D ?\b', 'rkd'	#record is not rakr
    $pronunciation = $pronunciation -creplace 'AH0 B L AY1 JH ?\b', 'obl'	#oblige is not oblij
    $pronunciation = $pronunciation -creplace 'K AH1 Z AH0 N ?\b', 'kuzn'	#cousin is not kusun
    $pronunciation = $pronunciation -creplace 'L OW1 N L IY0 ?\b', 'lone'	#lonely is not lonle
    $pronunciation = $pronunciation -creplace 'T UW1 Z D IY0 ?\b', 'tus'	#tuesday is not tusde
    $pronunciation = $pronunciation -creplace 'F EH1 R L IY0 ?\b', 'fare'	#fairly is not farle
    $pronunciation = $pronunciation -creplace 'R AH0 G AA1 R D ?\b', 're'	#regard is not rgard
    $pronunciation = $pronunciation -creplace 'IY1 Z AH0 L IY0 ?\b', 'esy'	#easily is not esle
    $pronunciation = $pronunciation -creplace 'R IH0 D UW1 S ?\b', 'redus'	#reduce is not rdus
    $pronunciation = $pronunciation -creplace 'IH1 N V OY0 S ?\b', 'nvs'	#invoice is not nvoes
    $pronunciation = $pronunciation -creplace 'S T AH1 D IY0 ?\b', 'stde'	#study is not stude
    $pronunciation = $pronunciation -creplace 'K ER0 EH1 K T ?\b', 'kr'	#correct is not krekt
    $pronunciation = $pronunciation -creplace 'K AH0 N OW1 T ?\b', 'knot'	#connote is not kot
    $pronunciation = $pronunciation -creplace 'AE1 D R EH2 S ?\b', 'adr'	#address is not adrs
    $pronunciation = $pronunciation -creplace 'N AH1 M B ER0 ?\b', 'num'	#number is not numbr
    $pronunciation = $pronunciation -creplace 'AH0 K AO1 R D ?\b', 'akr'	#accord is not akord
    $pronunciation = $pronunciation -creplace 'AH0 M Y UW1 Z ?\b', 'amus'	#amuse is not ameus
    $pronunciation = $pronunciation -creplace 'R IH0 T ER1 N ?\b', 'ret'	#return is not retEn
    $pronunciation = $pronunciation -creplace 'R EY1 L W EY2 ?\b', 'rl'	#railway is not ralua
    $pronunciation = $pronunciation -creplace 'B Y UW1 T IY0 ?\b', 'bte'	#beauty is not beute
    $pronunciation = $pronunciation -creplace 'F R AY1 D IY0 ?\b', 'fri'	#friday is not fride
    $pronunciation = $pronunciation -creplace 'B IH1 Z N AH0 S ?\b', 'bs' #business is not bsns
    $pronunciation = $pronunciation -creplace 'ER0 EY1 N JH ?\b', 'ara'	#arrange is not aranj
    $pronunciation = $pronunciation -creplace 'W EH1 DH ER0 ?\b', 'ueh'	#whether is not uehr
    $pronunciation = $pronunciation -creplace 'N IH1 R L IY0 ?\b', 'nee'	#nearly is not nEle
    $pronunciation = $pronunciation -creplace 'F L AW1 ER0 ?\b', 'flr'	#flour is not flAW1 r
    $pronunciation = $pronunciation -creplace 'IH2 N D IY1 D ?\b', 'ndt'	#indeed is not nded
    $pronunciation = $pronunciation -creplace 'K AH0 N F ER1 ?\b', 'kfer'	#confer is not kfr
    $pronunciation = $pronunciation -creplace 'R IY0 M IH1 T ?\b', 'rem'	#remit is not remet
    $pronunciation = $pronunciation -creplace 'N EY1 CH ER0 ?\b', 'natr'	#nature is not nacE
    $pronunciation = $pronunciation -creplace 'K AE1 N AA0 T ?\b', 'kn'	#cannot is not kanot
    $pronunciation = $pronunciation -creplace 'R IH0 P L AY1 ?\b', 'rep'	#reply is not repla
    $pronunciation = $pronunciation -creplace 'R IH1 S K T ?\b', 'reskd'	#risked is not rskd
    $pronunciation = $pronunciation -creplace 'D IH1 R L IY0 ?\b', 'dee'	#dearly is not dele
    $pronunciation = $pronunciation -creplace 'M AH1 N D IY0 ?\b', 'mun'	#monday is not mnde
    $pronunciation = $pronunciation -creplace 'EH1 K S EH2 S ?\b', 'eses'	#excess is not exs
    $pronunciation = $pronunciation -creplace 'S T R AO1 NG ?\b', 'str'	#strong is not strog
    $pronunciation = $pronunciation -creplace 'S T EH1 R Z ?\b', 'stAs'	#stairs is not stars
    $pronunciation = $pronunciation -creplace 'AA1 G AH0 S T ?\b', 'og'	#august is not agust
    $pronunciation = $pronunciation -creplace 'P ER1 S AH0 N ?\b', 'prs'	#person is not prsn
    $pronunciation = $pronunciation -creplace 'R IH1 D AH0 L ?\b', 'redl'	#riddle is not rdl
    $pronunciation = $pronunciation -creplace 'V AE1 L Y UW0 ?\b', 'vl'	#value is not valY u
    $pronunciation = $pronunciation -creplace 'IH2 M P EH1 L ?\b', 'mpl'	#impel is not mpel
    $pronunciation = $pronunciation -creplace 'S AH1 N D EY2 ?\b', 'sn'	#sunday is not snda
    $pronunciation = $pronunciation -creplace 'P R AY1 ER0 ?\b', 'prier'	#prior is not prir
    $pronunciation = $pronunciation -creplace 'EY1 P R AH0 L ?\b', 'apr'	#april is not aprl
    $pronunciation = $pronunciation -creplace 'F ... R W ... D ?\b', 'fd'	#forward is not fuEd
    $pronunciation = $pronunciation -creplace 'M ... N ... JH ?\b', 'mj'	#manage is not manj
    $pronunciation = $pronunciation -creplace 'EY1 JH AH0 N T ?\b', 'aj'	#agent is not ajnt
    $pronunciation = $pronunciation -creplace 'G AH1 V ER0 N ?\b', 'gv'	#govern is not gvEn
    $pronunciation = $pronunciation -creplace 'K AH0 M P L ?\b', 'kP'	#Pick up all compl...
    $pronunciation = $pronunciation -creplace 'K AH0 M P ?\b', 'kP'	#Pick up all comp...
    $pronunciation = $pronunciation -creplace 'IH2 N SH UH1 R ?\b', 'nz'	#insure is not nzu
    $pronunciation = $pronunciation -creplace 'R AE1 DH ER0 ?\b', 'rah'	#rather is not rahr
    $pronunciation = $pronunciation -creplace 'IH0 F EH1 K T ?\b', 'fk'	#effect is not efkt
    $pronunciation = $pronunciation -creplace 'F ER1 DH ER0 ?\b', 'fh'	#further is not frhr
    $pronunciation = $pronunciation -creplace 'IH0 K S EH1 L ?\b', 'esl'	#excel is not esel
    $pronunciation = $pronunciation -creplace 'AE1 K Y ER0 AH0 T ?\b', 'akra'	#accurate is not akrt
    $pronunciation = $pronunciation -creplace 'D R AE1 F T ?\b', 'drf'	#draft is not draft
    $pronunciation = $pronunciation -creplace 'AH0 P IH1 R ?\b', 'apr'	#appear is not aper
    $pronunciation = $pronunciation -creplace 'M AE1 N ER0 ?\b', 'mnE'	#manner is not manr
    $pronunciation = $pronunciation -creplace 'B EH1 T ER0 ?\b', 'btE'	#better is not betE
    $pronunciation = $pronunciation -creplace 'W AH1 N D ER0 ?\b', 'uun'	#wonder is not uU
    $pronunciation = $pronunciation -creplace 'AE1 N S ER0 ?\b', 'ans'	#answer is not ansr
    $pronunciation = $pronunciation -creplace 'D IH1 R ER0 ?\b', 'der'	#dearer is not derr
    $pronunciation = $pronunciation -creplace 'D R IH1 NG K ?\b', 'dreq'	#drink is not drq
    $pronunciation = $pronunciation -creplace 'K AA1 M AH0 N ?\b', 'kmn'	#common is not kn
    $pronunciation = $pronunciation -creplace 'R IY1 CH T ?\b', 'recd'	#reached is not rcd
    $pronunciation = $pronunciation -creplace 'M ER1 M ER0 ?\b', 'mEmE'	#murmur is not mnr
    $pronunciation = $pronunciation -creplace 'B IH0 K AH1 M ?\b', 'bk'	#become is not bkm
    $pronunciation = $pronunciation -creplace 'K AA1 M IH0 K ?\b', 'kmek'	#comic is not kk
    $pronunciation = $pronunciation -creplace 'S K W AO1 L ?\b', 'sqol'	#squall is not sqo
    $pronunciation = $pronunciation -creplace 'K IY1 P ER0 ?\b', 'kpr'	#keeper is not kepr
    $pronunciation = $pronunciation -creplace 'F R EH1 N D ?\b', 'fr'	#friend is not frend
    $pronunciation = $pronunciation -creplace 'HH IY1 R ?\b', 'her'	#here is not er
    $pronunciation = $pronunciation -creplace 'S T AE1 N D ?\b', 'stn'	#stand is not stand
    $pronunciation = $pronunciation -creplace 'T R AH1 S T ?\b', 'trs'	#trust is not trust
    $pronunciation = $pronunciation -creplace 'IH0 N AH1 F ?\b', 'nuf'	#enough is not enuf
    $pronunciation = $pronunciation -creplace 'IH2 N F ER1 ?\b', 'nfer'	#infer is not nfr
    $pronunciation = $pronunciation -creplace 'P AA1 R T S ?\b', 'pts'	#parts is not pAts
    $pronunciation = $pronunciation -creplace 'D AA1 L ER0 ?\b', 'do'	#dollar is not dolr
    $pronunciation = $pronunciation -creplace 'K AE1 R IY0 ?\b', 'kae'	#carry is not kare
    $pronunciation = $pronunciation -creplace 'F AA1 L OW0 ?\b', 'fo'	#follow is not folo
    $pronunciation = $pronunciation -creplace 'R IH0 N UW1 ?\b', 'renu'	#renew is not rnu
    $pronunciation = $pronunciation -creplace 'D EY1 L IY0 ?\b', 'dae'	#daily is not dale
    $pronunciation = $pronunciation -creplace 'R IH0 Z UW1 M ?\b', 'rsm'	#resume is not 
    $pronunciation = $pronunciation -creplace 'S K UW1 L ?\b', 'skl'	#school is not skul
    $pronunciation = $pronunciation -creplace 'K AH0 N UW1 ?\b', 'kanu'	#canoe is not ku
    $pronunciation = $pronunciation -creplace 'B R IH1 NG ?\b', 'br'	#bring is not breNg
    $pronunciation = $pronunciation -creplace 'AH0 W EH1 R ?\b', 'ar'	#aware is not auar
    $pronunciation = $pronunciation -creplace 'S P IY1 CH ?\b', 'sp'	#speech is not spec
    $pronunciation = $pronunciation -creplace 'D UW1 T IY0 ?\b', 'dte'	#duty is not dute
    $pronunciation = $pronunciation -creplace 'V IH1 Z IH0 T ?\b', 'veset'	#visit is not vst
    $pronunciation = $pronunciation -creplace 'OW1 N L IY0 ?\b', 'one'	#only is not onle
    $pronunciation = $pronunciation -creplace 'B IH1 Z IY0 ?\b', 'bese'	#busy is not bse
    $pronunciation = $pronunciation -creplace 'D IH0 Z AY1 ER0 ?\b', 'ds'	#desire is not dsir
    $pronunciation = $pronunciation -creplace 'AH0 B AW1 T ?\b', 'ab'	#about is not abau
    $pronunciation = $pronunciation -creplace 'K AA1 P IY0 ?\b', 'kpe'	#copy is not kope
    $pronunciation = $pronunciation -creplace 'AH0 M AH1 NG ?\b', 'mg'	#among is not amg
    $pronunciation = $pronunciation -creplace 'HH AW1 S ?\b', 'hus'	#house is not hAW1 s
    $pronunciation = $pronunciation -creplace 'AO1 F AH0 S ?\b', 'os'	#office is not ofs
    $pronunciation = $pronunciation -creplace 'JH UW2 L AY1 ?\b', 'ju'	#july is not juli
    $pronunciation = $pronunciation -creplace 'P OY1 N T ?\b', 'oe'	#point is not poent
    $pronunciation = $pronunciation -creplace 'P R UW1 V ?\b', 'prv'	#prove is not pruv
    $pronunciation = $pronunciation -creplace 'JH AH1 S T ?\b', 'j'	#just is not just
    $pronunciation = $pronunciation -creplace 'W ER1 L D ?\b', 'uu'	#world is not uerld
    $pronunciation = $pronunciation -creplace 'P R UW1 F ?\b', 'prf'	#proof is not pruf
    $pronunciation = $pronunciation -creplace 'CH AA1 R JH ?\b', 'j'	#charge is not cAj
    $pronunciation = $pronunciation -creplace 'Y AH1 NG ?\b', 'ug'	#young is not yaH1 g
    $pronunciation = $pronunciation -creplace 'K L IH1 R ?\b', 'kle'	#clear is not kler
    $pronunciation = $pronunciation -creplace 'P L IY1 Z ?\b', 'pl'	#please is not ples
    $pronunciation = $pronunciation -creplace 'S K IH1 L ?\b', 'skl'	#skill is not skel
    $pronunciation = $pronunciation -creplace 'B AA1 D IY0 ?\b', 'bo'	#body is not bode
    $pronunciation = $pronunciation -creplace 'P AW1 ER0 ?\b', 'pau'	#power is not paor
    $pronunciation = $pronunciation -creplace 'D EH1 R D ?\b', 'dAd'	#dared is not derd
    $pronunciation = $pronunciation -creplace 'AH0 G R IY1 ?\b', 'a'	#agree is not agre
    $pronunciation = $pronunciation -creplace 'TH AE1 NG K ?\b', 'ha'	#thank is not haq
    $pronunciation = $pronunciation -creplace 'S T AA1 K ?\b', 'sto'	#stock is not stok
    $pronunciation = $pronunciation -creplace 'IY1 DH ER0 ?\b', 'eh'	#either is not ehr
    $pronunciation = $pronunciation -creplace 'D EH1 R Z ?\b', 'dAs'	#dares is not ders
    $pronunciation = $pronunciation -creplace 'F L AO1 R ?\b', 'flr'	#floor is not flor
    $pronunciation = $pronunciation -creplace 'AE1 P AH0 L ?\b', 'apl'	#apple is not ap
    $pronunciation = $pronunciation -creplace 'T EH1 R Z ?\b', 'tEs'	#tears is not tars
    $pronunciation = $pronunciation -creplace 'S M AY1 L ?\b', 'smi'	#smile is not smil
    $pronunciation = $pronunciation -creplace 'AH0 K ER1 ?\b', 'okr'	#occur is not ukur
    $pronunciation = $pronunciation -creplace 'R AH0 F ER1 ?\b', 'rf'	#refer is not rfr
    $pronunciation = $pronunciation -creplace 'K AH1 V ER0 ?\b', 'kv'	#cover is not kvr
    $pronunciation = $pronunciation -creplace 'S EH1 N D ?\b', 'sen'	#send is not send
    $pronunciation = $pronunciation -creplace 'R IH1 S K ?\b', 'resk'	#risk is not rsk
    $pronunciation = $pronunciation -creplace 'M AE1 S K ?\b', 'mask'	#mask is not msk
    $pronunciation = $pronunciation -creplace 'AH1 V AH0 N ?\b', 'uvn'	#oven is not vn
    $pronunciation = $pronunciation -creplace 'B ER1 TH ?\b', 'berH'	#birth is not brh
    $pronunciation = $pronunciation -creplace 'AH0 L AW1 ?\b', 'al'	#allow is not alao
    $pronunciation = $pronunciation -creplace 'M IH1 S T ?\b', 'mest'	#mist is not mst
    $pronunciation = $pronunciation -creplace 'HH IY1 ?\b', 'e'	#he is not he
    $pronunciation = $pronunciation -creplace '^EY1 B AH0 L ?\b', 'abl'	#able is not b
    $pronunciation = $pronunciation -creplace 'B IH1 L T ?\b', 'bl'	#built is not belt
    $pronunciation = $pronunciation -creplace 'G R EY1 T ?\b', 'gr'	#great is not grat
    $pronunciation = $pronunciation -creplace 'trsW ER2 DH IY0 ?\b', 'trshe'	#trustworthy is not trsuhe
    $pronunciation = $pronunciation -creplace ' W ER\d DH IY0$', ' he'	#worthy at the end is he
    $pronunciation = $pronunciation -creplace ' W ER\d TH$', ' uh'	#worth at the end is uh
    $pronunciation = $pronunciation -creplace 'W ER1 [DT]H ?\b', 'uuh'	#worth is not uerH
    $pronunciation = $pronunciation -creplace 'T AE1 S K ?\b', 'task'	#task is not tsk
    $pronunciation = $pronunciation -creplace 'S T AA1 P ?\b', 'stp'	#stop is not stop
    $pronunciation = $pronunciation -creplace 'F AO1 R S ?\b', 'fs'	#force is not fors
    $pronunciation = $pronunciation -creplace 'S P IY1 K ?\b', 'sp'	#speak is not spek
    $pronunciation = $pronunciation -creplace 'ER1 L IY0 ?\b', 'ere'	#early is not rle
    $pronunciation = $pronunciation -creplace 'IH0 NG L IY0 ?\b', 'G' # ...ingly is G
    $pronunciation = $pronunciation -creplace 'F AY1 N D ?\b', 'fi'	#find is not find
    $pronunciation = $pronunciation -creplace '^AW1 N S ?\b', 'aons'	#ounce is not ns
    $pronunciation = $pronunciation -creplace 'S IH2 CH UW0 EY1 SH AH0 N ?\b', 'setz'
    $pronunciation = $pronunciation -creplace 'W ER1 L ?\b', 'uerl'	#whirl is not erl
    $pronunciation = $pronunciation -creplace 'K AY1 N D ?\b', 'ki'	#kind is not kind
    $pronunciation = $pronunciation -creplace 'K ER1 S ?\b', 'kurs'	#curse is not krs
    $pronunciation = $pronunciation -creplace 'L IH1 S T ?\b', 'ls'	#list is not lest
    $pronunciation = $pronunciation -creplace 'R IY1 CH ?\b', 'rec'	#reach is not rc
    $pronunciation = $pronunciation -creplace 'W AY1 ER0 ?\b', 'ir'	#wire is not uir
    $pronunciation = $pronunciation -creplace '^R IH1 NG ?\b', 'reg'	#ring is not rg
    $pronunciation = $pronunciation -creplace 'P AA1 R T ?\b', 'pt'	#part is not pAt
    $pronunciation = $pronunciation -creplace 'Y AA1 T ?\b', 'eot'	#yacht is not yat
    $pronunciation = $pronunciation -creplace 'CH EH1 R ?\b', 'cA'	#chair is not car
    $pronunciation = $pronunciation -creplace 'SH EH1 R ?\b', 'zA'	#share is not zar
    $pronunciation = $pronunciation -creplace 'T AY1 ER0 ?\b', 'ti'	#tire is not tir
    $pronunciation = $pronunciation -creplace 'R AY1 T ?\b', 'ri'	#write is not rit
    $pronunciation = $pronunciation -creplace '^D IY1 L ?\b', 'de'	#deal is not del
    $pronunciation = $pronunciation -creplace 'N AY1 T ?\b', 'ni'	#night is not nit
    $pronunciation = $pronunciation -creplace 'N EH1 S AH0 S EH2 R IY0 ?\b', 'ness'
    $pronunciation = $pronunciation -creplace 'S AH1 CH ?\b', 'sc'	#such is not suc
    $pronunciation = $pronunciation -creplace 'R AY1 T ?\b', 'ri'	#right is not rit
    $pronunciation = $pronunciation -creplace '^Y UW1 TH ?\b', 'euh'	#you is not uh
    $pronunciation = $pronunciation -creplace 'L AY1 T ?\b', 'li'	#light is not lit
    $pronunciation = $pronunciation -creplace 'DH EH1 R ?\b', 'H'	#their is not her
    $pronunciation = $pronunciation -creplace 'L AO1 NG ?\b', 'lg'	#long is not log
    $pronunciation = $pronunciation -creplace 'L UW1 Z ?\b', 'luz'	#lose is not lus
    $pronunciation = $pronunciation -creplace 'W EH1 R ?\b', 'ar'	#where is not uar
    $pronunciation = $pronunciation -creplace 'SH UH1 R ?\b', 'zu'	#sure is not zur
    $pronunciation = $pronunciation -creplace 'W IH1 CH ?\b', 'c'	#which is not uec
    $pronunciation = $pronunciation -creplace 'M AY1 N ?\b', 'min'	#mine is not man
    $pronunciation = $pronunciation -creplace 'M AH1 CH ?\b', 'mc'	#much is not muc
    $pronunciation = $pronunciation -creplace 'W IH1 DH ?\b', 'eh'	#with is not ueh
    $pronunciation = $pronunciation -creplace 'DH EH1 R ?\b', 'H'	#there is not her
    $pronunciation = $pronunciation -creplace 'W IH1 SH ?\b', 'uz'	#wish is not uez
    $pronunciation = $pronunciation -creplace 'DH AE1 T ?\b', 'ha'	#that is not hat
    $pronunciation = $pronunciation -creplace 'DH EH1 M ?\b', 'hm'	#them is not hem
    $pronunciation = $pronunciation -creplace 'DH EH1 N ?\b', 'hn'	#then is not hen
    $pronunciation = $pronunciation -creplace 'AA1 R CH ?\b', 'Ac'	#arch is not arc
    $pronunciation = $pronunciation -creplace 'HH UW1 M ?\b', 'hum'	#whom is not hm
    $pronunciation = $pronunciation -creplace 'R IH1 T ?\b', 'ret'	#writ is not rt
    $pronunciation = $pronunciation -creplace 'W IY1 K ?\b', 'ek'	#weak is not uek
    $pronunciation = $pronunciation -creplace 'B IH1 L ?\b', 'bl'	#bill is not bel
    $pronunciation = $pronunciation -creplace 'HH AE1 V ?\b', 'v'	#have is not hav
    $pronunciation = $pronunciation -creplace 'W ER1 D ?\b', 'ud'	#word is not erd
    $pronunciation = $pronunciation -creplace 'D EH1 R ?\b', 'dA'	#dare is not dar
    $pronunciation = $pronunciation -creplace 'T EH1 R ?\b', 'tE'	#tear is not tar
    $pronunciation = $pronunciation -creplace 'G AO1 N ?\b', 'gn'	#gone is not gon
    $pronunciation = $pronunciation -creplace 'D IH1 R ?\b', 'de'	#dear is not der
    $pronunciation = $pronunciation -creplace 'F UH1 L ?\b', 'fu'	#full is not ful
    $pronunciation = $pronunciation -creplace 'ER1 TH ?\b', 'erH'	#earth is not rh
    $pronunciation = $pronunciation -creplace 'EH1 L S ?\b', 'ls'	#else is not els
    $pronunciation = $pronunciation -creplace 'B UH1 K ?\b', 'bk'	#book is not buk
    $pronunciation = $pronunciation -creplace 'K EH1 R ?\b', 'ka'	#care is not kar
    $pronunciation = $pronunciation -creplace 'R IH1 R ?\b', 'rer'	#rear is not rr
    $pronunciation = $pronunciation -creplace 'R IY1 L ?\b', 're'	#real is not rel
    $pronunciation = $pronunciation -creplace 'N AH1 N ?\b', 'nun'	#none is not nn
    $pronunciation = $pronunciation -creplace 'R UW1 L ?\b', 'rl'	#rule is not rul
    $pronunciation = $pronunciation -creplace 'M UW1 V ?\b', 'mu'	#move is not muv
    $pronunciation = $pronunciation -creplace 'M AY1 L ?\b', 'mi'	#mile is not mal
    $pronunciation = $pronunciation -creplace 'M UW1 N ?\b', 'mun'	#moon is not mn
    $pronunciation = $pronunciation -creplace 'S AY1 D ?\b', 'si'	#side is not sid
    $pronunciation = $pronunciation -creplace 'N IH1 R ?\b', 'nE'	#near is not ner
    $pronunciation = $pronunciation -creplace 'N AH1 M ?\b', 'num'	#numb is not nm
    $pronunciation = $pronunciation -creplace 'R UW1 M ?\b', 'rm'	#room is not rum
    $pronunciation = $pronunciation -creplace 'L UH1 K ?\b', 'lu'	#look is not luk
    $pronunciation = $pronunciation -creplace 'M EY1 L ?\b', 'ma'	#mail is not mal
    $pronunciation = $pronunciation -creplace 'N UW1 N ?\b', 'nun'	#noon is not nn
    $pronunciation = $pronunciation -creplace 'W IY1 K ?\b', 'ek'	#week is not uek
    $pronunciation = $pronunciation -creplace 'B EH1 D ?\b', 'bd'	#bed is not bed
    $pronunciation = $pronunciation -creplace 'Y UW1 S ?\b', 'eu'	#use is not eus
    $pronunciation = $pronunciation -creplace 'Y EH1 S ?\b', 'ye'	#yes is not yes
    $pronunciation = $pronunciation -creplace 'Y UH1 R Z ?\b', 'u'	#yours is not rs
    $pronunciation = $pronunciation -creplace 'Y AO1 R ?\b', 'u'	#your is not eor
    $pronunciation = $pronunciation -creplace 'R IH1 M ?\b', 'rem'	#rim is not rm
    $pronunciation = $pronunciation -creplace 'B AE1 D ?\b', 'bd'	#bad is not bad
    $pronunciation = $pronunciation -creplace 'W IH1 N ?\b', 'uen'	#win is not un
    $pronunciation = $pronunciation -creplace 'AE1 S K ?\b', 'sk'	#ask is not ask
    $pronunciation = $pronunciation -creplace '^K AA1 R$', 'kr'	#car is not kor
    $pronunciation = $pronunciation -creplace 'R IH1 D ?\b', 'red'	#rid is not rd
    $pronunciation = $pronunciation -creplace 'W UH1 D ?\b', 'd'	#would is not ud
    $pronunciation = $pronunciation -creplace 'IH0 NG Z ?\b', 'S' # ...ings is S
    $pronunciation = $pronunciation -creplace 'HH AW1 ?\b', 'au'	#how is not hao
    $pronunciation = $pronunciation -creplace 'K AE1 N ?\b', 'k'	#can is not kan
    $pronunciation = $pronunciation -creplace 'EH1 V R IY0 TH IH2 NG ?\b', 'evh'
    $pronunciation = $pronunciation -creplace 'W AY1 L$', 'il'	#while is not uil
    $pronunciation = $pronunciation -creplace 'DH EY1 ?\b', 'he'	#they is not ha
    $pronunciation = $pronunciation -creplace 'F ER0 T ?\b', 'ft'	#fort is not fEt
    $pronunciation = $pronunciation -creplace 'F AO1 R ?\b', 'f'	#for is not for
    $pronunciation = $pronunciation -creplace '^W IY1$', 'w'	#we is not ue
    $pronunciation = $pronunciation -creplace 'S AH1 B ?\b', 's'	#sub is not sb
    $pronunciation = $pronunciation -creplace '^K ER1$', 'kur'	#cur is not kr
    $pronunciation = $pronunciation -creplace 'EH1 N IY0 TH IH2 NG ?\b', 'neh'
    $pronunciation = $pronunciation -creplace '^Y UW1 ?\b', 'u'	#you is not eu
    $pronunciation = $pronunciation -creplace 'P AA1 S AH0 B AH0 L ?\b', 'pos'
    $pronunciation = $pronunciation -creplace 'M IH1 N ER0 AH0 L ?\b', 'mnerl'
    $pronunciation = $pronunciation -creplace 'K AA1 M$', 'kam'	#calm is not k
    $pronunciation = $pronunciation -creplace 'M AY2 S EH1 L F ?\b', 'mas'	#myself is not mis
    $pronunciation = $pronunciation -creplace '^M AY1 ?\b', 'ma'	#my is not mi
    $pronunciation = $pronunciation -creplace '^AO1 L \b$', 'O'	#all is not o
    $pronunciation = $pronunciation -creplace '^AW1 T$', 'au'	#out is not aot
    $pronunciation = $pronunciation -creplace 'JH EH1 N ER0 AH0 L ?\b', 'jen'
    $pronunciation = $pronunciation -creplace '^W AO1 R ?\b', 'uo'	#war is not uor
    $pronunciation = $pronunciation -creplace 'B IY1 ?\b', 'b'	#be is not be
    $pronunciation = $pronunciation -creplace 'HH AE1 N D AH0 L ?\b', 'hndl'
    $pronunciation = $pronunciation -creplace 'M IH1 N AH0 M AH0 M', 'mnemn'	#minimum is not mnemem
    $pronunciation = $pronunciation -creplace '^IH1 N \b', 'n'	#in is not en
    $pronunciation = $pronunciation -creplace 'IH0 N ?\b', 'n'	#in is not en
    $pronunciation = $pronunciation -creplace 'S AH1 M TH IH0 NG ?\b', 'smh'
    $pronunciation = $pronunciation -creplace 'S EH1 N S AH0 S ?\b', 'senss'
    $pronunciation = $pronunciation -creplace '^IH1 Z$', 's'	#is is not es
    $pronunciation = $pronunciation -creplace 'S EH1 V ER0 AH0 L ?\b', 'sev'
    $pronunciation = $pronunciation -creplace '^IH1 T ?\b', 't'	#it is not et
    $pronunciation = $pronunciation -creplace 'M AO1 R N IH0 NG ?\b', 'mng'
    $pronunciation = $pronunciation -creplace 'AH0 G EH1 N S T ?\b', 'agns'
    $pronunciation = $pronunciation -creplace '^W AY1$', 'i'	#why is not ui
    $pronunciation = $pronunciation -creplace 'HH OW0 T EH1 L ?\b', 'hotel'
    $pronunciation = $pronunciation -creplace 'P R EH1 Z AH0 N T ?\b', 'pr'
    $pronunciation = $pronunciation -creplace 'AH0 N AH1 DH ER0 ?\b', 'nuh'
    $pronunciation = $pronunciation -creplace '^AA1 R$', 'r'	#are is not ar
    $pronunciation = $pronunciation -creplace 'K AA1 L IH0 JH ?\b', 'kolej'
    $pronunciation = $pronunciation -creplace 'TH ER1 OW0 L IY0 ?\b', 'He'
    $pronunciation = $pronunciation -creplace 'P AH1 B L IH0 SH ?\b', 'pb'
    $pronunciation = $pronunciation -creplace 'N OW1 T AH0 S ?\b', 'notes'
    $pronunciation = $pronunciation -creplace 'S AA1 L AH0 D ?\b', 'soled'
    $pronunciation = $pronunciation -creplace 'S AA1 L AH0 M ?\b', 'solem'
    $pronunciation = $pronunciation -creplace 'N AH1 TH IH0 NG ?\b', 'nh'
    $pronunciation = $pronunciation -creplace '^AH1 V$', 'o'	#of is not v
    $pronunciation = $pronunciation -creplace 'M IH1 N AH0 T ?\b', 'mnet'
    $pronunciation = $pronunciation -creplace 'K AH1 N T R IY0 ?\b', 'kt'
    $pronunciation = $pronunciation -creplace 'P AH1 B L IH0 K ?\b', 'pb'
    $pronunciation = $pronunciation -creplace 'B IH0 G IH1 N ?\b', 'bgen'
    $pronunciation = $pronunciation -creplace 'HH AE1 P AH0 N ?\b', 'hap'
    $pronunciation = $pronunciation -creplace 'S IH1 S T AH0 M ?\b', 'ss'
    $pronunciation = $pronunciation -creplace 'L IH1 T AH0 L ?\b', 'let'
    $pronunciation = $pronunciation -creplace 'W UH1 M AH0 N ?\b', 'umn'
    $pronunciation = $pronunciation -creplace 'K AH0 M EH1 N ?\b', 'kmn'
    $pronunciation = $pronunciation -creplace 'AO1 L W EY2 Z ?\b', 'ols'
    $pronunciation = $pronunciation -creplace 'P ER1 P AH0 S ?\b', 'prp'
    $pronunciation = $pronunciation -creplace 'P IY1 P AH0 L ?\b', 'pep'
    $pronunciation = $pronunciation -creplace 'AH0 N T IH1 L ?\b', 'nte'
    $pronunciation = $pronunciation -creplace 'D UH1 R IH0 NG ?\b', 'dr'
    $pronunciation = $pronunciation -creplace 'F ER0 G AA1 T ?\b', 'fgt'
    $pronunciation = $pronunciation -creplace 'R AH0 S IY1 V ?\b', 'rse'
    $pronunciation = $pronunciation -creplace '(Z|S|C)H AH0 N ?\b', 'z'
    $pronunciation = $pronunciation -creplace 'G IH1 V AH0 N ?\b', 'ge'
    $pronunciation = $pronunciation -creplace 'B IH0 K AO1 Z ?\b', 'ks'
    $pronunciation = $pronunciation -creplace 'B IH0 L IY1 V ?\b', 'be'
    $pronunciation = $pronunciation -creplace 'B IH0 L IY1 F ?\b', 'be'
    $pronunciation = $pronunciation -creplace 'B IH0 F AO1 R ?\b', 'bf'
    $pronunciation = $pronunciation -creplace 'AO1 L S OW0 ?\b', 'oso'
    $pronunciation = $pronunciation -creplace 'M AE1 T ER0 ?\b', 'mat'
    $pronunciation = $pronunciation -creplace 'EH1 V R IY0 ?\b', 'eve'
    $pronunciation = $pronunciation -creplace 'N EH1 K S T ?\b', 'nes'
    $pronunciation = $pronunciation -creplace 'K AH0 N OW1 ?\b', 'kno'
    $pronunciation = $pronunciation -creplace 'AE1 F T ER0 ?\b', 'aft'
    $pronunciation = $pronunciation -creplace 'AH0 G EH1 N ?\b', 'agn'
    $pronunciation = $pronunciation -creplace 'AH0 P AA1 N ?\b', 'pon'
    $pronunciation = $pronunciation -creplace 'JH EH1 N T ?\b', 'jnt'
    $pronunciation = $pronunciation -creplace 'F EY1 V ER0 ?\b', 'fa'
    $pronunciation = $pronunciation -creplace 'AH0 W EH1 R ?\b', 'ar'
    $pronunciation = $pronunciation -creplace '^AO1 R D ER0 ?\b', 'od'
    $pronunciation = $pronunciation -creplace 'G L EH1 R ?\b', 'glar'
    $pronunciation = $pronunciation -creplace 'L EH1 T ER0 ?\b', 'le'
    $pronunciation = $pronunciation -creplace 'S IH1 N S ?\b', 'sens'
    $pronunciation = $pronunciation -creplace 'V EH1 R IY0 ?\b', 've'
    $pronunciation = $pronunciation -creplace 'TH IH1 NG K ?\b', 'hh'
    $pronunciation = $pronunciation -creplace 'N EH1 V ER0 ?\b', 'nv'
    $pronunciation = $pronunciation -creplace 'D R AO1 N ?\b', 'dron'
    $pronunciation = $pronunciation -creplace 'AH2 N D ER0 ?\b', 'U'
    $pronunciation = $pronunciation -creplace 'S T EH1 D ?\b', 'std'
    $pronunciation = $pronunciation -creplace 'CH EY1 N JH ?\b', 'c'
    $pronunciation = $pronunciation -creplace 'F ER1 S T ?\b', 'fes'
    $pronunciation = $pronunciation -creplace 'W AA1 N T ?\b', 'ont'
    $pronunciation = $pronunciation -creplace 'T R UW1 TH ?\b', 'tr'
    $pronunciation = $pronunciation -creplace 'TH ER1 OW0 ?\b', 'He'
    $pronunciation = $pronunciation -creplace 'AH0 K ER1 ?\b', 'okr'
    $pronunciation = $pronunciation -creplace 'K AA1 M R ?\b', 'kmr'
    $pronunciation = $pronunciation -creplace 'S T IH1 L ?\b', 'ste'
    $pronunciation = $pronunciation -creplace 'S P EH1 L ?\b', 'spl'
    $pronunciation = $pronunciation -creplace 'K AO1 R S ?\b', 'krs'
    $pronunciation = $pronunciation -creplace '^AH1 DH ER0 ?\b', 'uh'
    $pronunciation = $pronunciation -creplace 'AH1 N D ER0 ?\b', 'U'
    $pronunciation = $pronunciation -creplace 'P EH1 N D ?\b', 'pnd'
    $pronunciation = $pronunciation -creplace 'F R AH1 M ?\b', 'fm'
    $pronunciation = $pronunciation -creplace 'T OW1 L D ?\b', 'to'
    $pronunciation = $pronunciation -creplace 'M OW2 S T ?\b', 'mo'
    $pronunciation = $pronunciation -creplace 'T W IY1 N ?\b', 'tn'
    $pronunciation = $pronunciation -creplace 'P AA1 R T ?\b', 'pt'
    $pronunciation = $pronunciation -creplace 'M OW1 S T ?\b', 'mo'
    $pronunciation = $pronunciation -creplace 'EH1 V ER0 ?\b', 'ev'
    $pronunciation = $pronunciation -creplace 'TH IH0 NG ?\b', 'hg'
    $pronunciation = $pronunciation -creplace 'TH IH1 NG ?\b', 'hg'
    $pronunciation = $pronunciation -creplace 'TH IH2 NG ?\b', 'hg'
    $pronunciation = $pronunciation -creplace 'EH1 N IY0 ?\b', 'ne'
    $pronunciation = $pronunciation -creplace 'F AO1 R M ?\b', 'fm'
    $pronunciation = $pronunciation -creplace 'M AH1 S T ?\b', 'mu'
    $pronunciation = $pronunciation -creplace 'EH1 N IY0 ?\b', 'ne'
    $pronunciation = $pronunciation -creplace 'K S AH0 Z ?\b', 'xs'
    $pronunciation = $pronunciation -creplace 'B AW1 N D ?\b', 'bn'
    $pronunciation = $pronunciation -creplace 'G L AE1 D ?\b', 'gl'
    $pronunciation = $pronunciation -creplace 'S T EY1 T ?\b', 'st'
    $pronunciation = $pronunciation -creplace 'T AO1 K ?\b', 'tok'
    $pronunciation = $pronunciation -creplace 'TH R IY1 ?\b', 'he'
    $pronunciation = $pronunciation -creplace 'L AY1 V ?\b', 'lev'
    $pronunciation = $pronunciation -creplace 'D AH1 Z ?\b', 'duz'
    $pronunciation = $pronunciation -creplace 'DH OW1 Z ?\b', 'hs'
    $pronunciation = $pronunciation -creplace 'HH IH1 M ?\b', 'em'
    $pronunciation = $pronunciation -creplace 'OW2 V ER0 ?\b', 'O'
    $pronunciation = $pronunciation -creplace 'OW1 V ER0 ?\b', 'O'
    $pronunciation = $pronunciation -creplace 'T AO1 T ?\b', 'tot'
    $pronunciation = $pronunciation -creplace 'F OW1 K ?\b', 'fok'
    $pronunciation = $pronunciation -creplace 'DH IH1 S ?\b', 'hs'
    $pronunciation = $pronunciation -creplace 'B AO1 L ?\b', 'bol'
    $pronunciation = $pronunciation -creplace 'SH UH1 D ?\b', 'zd'
    $pronunciation = $pronunciation -creplace 'K AA1 T ?\b', 'kot'
    $pronunciation = $pronunciation -creplace 'M AE1 N ?\b', 'man'
    $pronunciation = $pronunciation -creplace 'W EH1 R ?\b', 'ar'
    $pronunciation = $pronunciation -creplace 'D IH1 D ?\b', 'dt'
    $pronunciation = $pronunciation -creplace 'B IH1 G ?\b', 'bg'
    $pronunciation = $pronunciation -creplace 'AO1 F T ?\b', 'of'
    $pronunciation = $pronunciation -creplace 'W AH1 T ?\b', 'ot'
    $pronunciation = $pronunciation -creplace 'W ER1 K ?\b', 'rk'
    $pronunciation = $pronunciation -creplace 'W EH1 N ?\b', 'en'
    $pronunciation = $pronunciation -creplace 'D EH1 F ?\b', 'df'
    $pronunciation = $pronunciation -creplace 'D EY1 T ?\b', 'dt'
    $pronunciation = $pronunciation -creplace 'B EH1 G ?\b', 'bg'
    $pronunciation = $pronunciation -creplace 'W AH2 N ?\b', 'un'
    $pronunciation = $pronunciation -creplace 'G AA1 T ?\b', 'gt'
    $pronunciation = $pronunciation -creplace 'S AH0 Z ?\b', 'ss'
    $pronunciation = $pronunciation -creplace 'K AH2 M ?\b', 'km'
    $pronunciation = $pronunciation -creplace 'K AH2 M ?\b', 'km'
    $pronunciation = $pronunciation -creplace 'K AA1 Z ?\b', 'ks'
    $pronunciation = $pronunciation -creplace 'S EH1 Z ?\b', 'ss'
    $pronunciation = $pronunciation -creplace 'EH1 N D ?\b', 'nd'
    $pronunciation = $pronunciation -creplace 'IH0 N D ?\b', 'nd'
    $pronunciation = $pronunciation -creplace 'S UW1 N ?\b', 'sn'
    $pronunciation = $pronunciation -creplace 'N EY1 M ?\b', 'na'
    $pronunciation = $pronunciation -creplace 'L AY1 K ?\b', 'la'
    $pronunciation = $pronunciation -creplace 'SH IH1 P ?\b', 'z'
    $pronunciation = $pronunciation -creplace 'L AO1 R ?\b', 'lr'
    $pronunciation = $pronunciation -creplace 'G IH1 V ?\b', 'ge'
    $pronunciation = $pronunciation -creplace 'G EY1 V ?\b', 'ga'
    $pronunciation = $pronunciation -creplace 'T AY1 M ?\b', 'tm'
    $pronunciation = $pronunciation -creplace 'T EH1 L ?\b', 'te'
    $pronunciation = $pronunciation -creplace 'G ER1 L ?\b', 'gl'
    $pronunciation = $pronunciation -creplace '^K AA1 M ?\b', 'k'
    $pronunciation = $pronunciation -creplace 'T IH1 L ?\b', 'te'
    $pronunciation = $pronunciation -creplace '^K AH0 M ?\b', 'k'
    $pronunciation = $pronunciation -creplace '^F AA1 R$', 'fa'
    $pronunciation = $pronunciation -creplace '^K AH0 N ?\b', 'k'
    $pronunciation = $pronunciation -creplace 'W IH1 L ?\b', 'l'
    #$pronunciation = $pronunciation -creplace 'S AO1 ?\b', 'so'
    $pronunciation = $pronunciation -creplace 'IH0 NG ?\b', 'g'
    $pronunciation = $pronunciation -creplace '^AO1 L ?\b', 'O'
    $pronunciation = $pronunciation -creplace '^W ER1$', 'er'
    $pronunciation = $pronunciation -creplace 'L AO1 ?\b', 'lo'
    $pronunciation = $pronunciation -creplace 'G OW1 ?\b', 'g'
    $pronunciation = $pronunciation -creplace '^AH0 Z ?\b', 's'
    $pronunciation = $pronunciation -creplace 'AO1 L ?\b', 'o'
    $pronunciation = $pronunciation -creplace 'UH1 D ?\b', 'd'
    $pronunciation = $pronunciation -creplace 'HH ER1$', 'er'

    # Dumb exceptions
    $pronunciation = $pronunciation -creplace 'K AW1 N T ?\b', 'knt'	#count is not kt
    $pronunciation = $pronunciation -creplace 'EH1 M P T IY0 ?\b', 'mte'	#empty is not mpte
    $pronunciation = $pronunciation -creplace 'IH0 V EH1 N T ?\b', 'evnt'	#event is not event
    $pronunciation = $pronunciation -creplace 'AH0 P EH1 R AH0 N T ?\b', 'aprnt'	#apparent is not apernt
    $pronunciation = $pronunciation -creplace 'D UW1 M D ?\b', 'dumd'	#doomed is not dmd
    $pronunciation = $pronunciation -creplace 'IH2 N V AH0 N T AO1 R IY0 ?\b', 'nvntre'	#inventory is not nvntore
    $pronunciation = $pronunciation -creplace 'M OW1 N D ?\b', 'mond'	#moaned is not mnd
    #$pronunciation = $pronunciation -creplace 'IH0 G Z EH1 M P T ?\b', 'xemt'	#exempt is not esemt
    $pronunciation = $pronunciation -creplace 'reF AH1 N D ?\b', 'rfnd'	#refund is not refnd
    $pronunciation = $pronunciation -creplace 'uenT ER0 ?\b', 'uentr'	#winter is not uentE
    $pronunciation = $pronunciation -creplace 'P R nT ?\b', 'prent'	#print is not prnt
    $pronunciation = $pronunciation -creplace 'S EH1 K AH0 N D ?\b', 'seknd'	#second is not sekd
    $pronunciation = $pronunciation -creplace 'OW1 L D ER0 ?\b', 'oldr'	#older is not oldE
    $pronunciation = $pronunciation -creplace 'K OW1 L D ER0 ?\b', 'koldr'	#colder is not koldE
    $pronunciation = $pronunciation -creplace 'T EH1 N AH0 S ?\b', 'tnes'	#tennis is not tns
    $pronunciation = $pronunciation -creplace 'T IH1 M IH0 D ?\b', 'tmed'	#timid is not tmd
    $pronunciation = $pronunciation -creplace 'EH1 S T AH0 M AH0 T ?\b', 'estmat'	#estimate is not estmt
    $pronunciation = $pronunciation -creplace '^T IH1 N ?\b', 'ten'	#tin is not tn
    $pronunciation = $pronunciation -creplace 'R EH1 Z IH0 D AH0 N S ?\b', 'rsedns'	#residence is not resdns
    $pronunciation = $pronunciation -creplace 'W IH1 Z D AH0 M ?\b', 'uesdm'	#wisdom is not usdm
    $pronunciation = $pronunciation -creplace 'R IH0 T EY1 N ?\b', 'retn'	#retain is not rtn
    $pronunciation = $pronunciation -creplace 'D AE1 N S ?\b', 'dans'	#dance is not dns
    $pronunciation = $pronunciation -creplace 'T AE1 N ?\b', 'tan'	#tan is not tn
    $pronunciation = $pronunciation -creplace 'T EH1 M P AH0 L ?\b', 'tmpl'	#temple is not tmp
    $pronunciation = $pronunciation -creplace 'D IH0 T EY1 N ?\b', 'detn'	#detain is not dtn
    $pronunciation = $pronunciation -creplace 'B UH1 L IH0 T AH0 N ?\b', 'buletn'	#bulletin is not bultn
    $pronunciation = $pronunciation -creplace 'S AH1 D AH0 N ?\b', 'sudn'	#sudden is not sdn
    $pronunciation = $pronunciation -creplace 'S AH0 S T EY1 N ?\b', 'sstn'	#sustain is not sustn
    $pronunciation = $pronunciation -creplace 'D IH1 N ER0 ?\b', 'dnr'	#dinner is not dnE
    $pronunciation = $pronunciation -creplace 'P ER0 M IH1 T ?\b', 'prmet'	#permit is not pEmet
    $pronunciation = $pronunciation -creplace 'ptN ER0 ?\b', 'pAtE'	#partner is not ptnE
    $pronunciation = $pronunciation -creplace 'F IH1 R D ?\b', 'ferd'	#feared is not fEd
    $pronunciation = $pronunciation -creplace 'P IH1 R IY0 AH0 D ?\b', 'PEd'	#period is not peread
    $pronunciation = $pronunciation -creplace 'F AA1 R M ER0 Z ?\b', 'fAmY'	#farmers is not fAmrs
    $pronunciation = $pronunciation -creplace 'L EY1 B ER0 D ?\b', 'labrd'	#labored is not labEd
    $pronunciation = $pronunciation -creplace 'cAM AH0 N ?\b', 'cAman'	#chairman is not cAmn
    $pronunciation = $pronunciation -creplace 'T EY1 P ER0 D ?\b', 'taprd'	#tapered is not tapEd        
    $pronunciation = $pronunciation -creplace 'G AA1 R D IY0 AH0 N ?\b', 'gAdean'	#guardian is not gAdn
    $pronunciation = $pronunciation -creplace 'TH ER1 D IY2 ?\b', 'HEte'	#thirty is not Hrde
    $pronunciation = $pronunciation -creplace 'K ER1 T IY0 AH0 S ?\b', 'kEtus'	#courteous is not kEteas
    $pronunciation = $pronunciation -creplace 'S ER1 V ?\b', 'sev'	#serve is not sEv
    $pronunciation = $pronunciation -creplace 'T AH0 W AO1 R D ?\b', 'tod'	#toward is not tuod
    $pronunciation = $pronunciation -creplace 'sevAH0 ss', 'sevess'	#services is not sEvss
    $pronunciation = $pronunciation -creplace 'sevAH0 S', 'seves'	#service is not sEvs
    #$pronunciation = $pronunciation -creplace 'S ER1 V AH0 S ?\b', 'seves'	#service is not sEvs
    $pronunciation = $pronunciation -creplace 'AO1 R K AH0 S T R AH0 ?\b', 'okestra'	#orchestra is not okstr 
    $pronunciation = $pronunciation -creplace 'S ER1 T AH0 N ?\b', 'setn'	#certain is not sEtn
    $pronunciation = $pronunciation -creplace 'P L EH1 ZH ER0 ?\b', 'plez'	#pleasure is not plezE
    $pronunciation = $pronunciation -creplace 'AE2 S ER0 T EY1 N ?\b', 'asetn'	#ascertain is not asEtn
    $pronunciation = $pronunciation -creplace 'W ER1 IY0 ?\b', 'uue'	#worry is not ere
    $pronunciation = $pronunciation -creplace 'T AH0 W AO1 R D Z ?\b', 'tods'	#towards is not tuods
    $pronunciation = $pronunciation -creplace 'S ER1 P L AH0 S ?\b', 'seplus'	#surplus is not sEplus
    $pronunciation = $pronunciation -creplace 'S ER1 K AH0 L ?\b', 'sekl'	#circle is not sEkl
    $pronunciation = $pronunciation -creplace 'L AA1 R JH ER0 ?\b', 'laje'	#larger is not lAjE
    $pronunciation = $pronunciation -creplace 'L ER1 N ?\b', 'len'	#learn is not lEn
    $pronunciation = $pronunciation -creplace 'L AA1 R JH ?\b', 'laj'	#large is not lAj
    $pronunciation = $pronunciation -creplace 'S ER1 F AH0 S ?\b', 'sefas'	#surface is not sEfus
    $pronunciation = $pronunciation -creplace 'D AO1 R W EY2 ?\b', 'dorua'	#doorway is not doua
    $pronunciation = $pronunciation -creplace 'B AO1 R D ER0 ?\b', 'bodE'	#border is not bod
    $pronunciation = $pronunciation -creplace 'AO1 TH ER0 ?\b', 'oHr'	#author is not oHE
    $pronunciation = $pronunciation -creplace 'HH AO1 R S ?\b', 'hors'	#horse is not hos
    $pronunciation = $pronunciation -creplace 'S ER0 P R AY1 Z ?\b', 'sepris'	#surprise is not sEpriz
    $pronunciation = $pronunciation -creplace '^T ER1 N ?\b', 'ten'	#turn is not tn
    $pronunciation = $pronunciation -creplace '^T ER1 M ?\b', 'tem'	#terms is not tms
    $pronunciation = $pronunciation -creplace 'S T AO1 R IY0 ?\b', 'store'	#story is not stoe
    $pronunciation = $pronunciation -creplace '^S EH1 L F$', 'self'	#self is not s
    $pronunciation = $pronunciation -creplace 'B AE1 G IH0 JH ?\b', 'bgj'	#baggage is not bagj
    $pronunciation = $pronunciation -creplace 'K ER1 IH0 JH ?\b', 'krj'	#courage is not kej
    $pronunciation = $pronunciation -creplace 'F ER1 N IH0 CH ER0 ?\b', 'fnetr'	#furniture is not fncE
    $pronunciation = $pronunciation -creplace 'P ER0 T EY1 N ?\b', 'pEtn'	#pertain is not prtn
    $pronunciation = $pronunciation -creplace 'S ER1 T AH0 F AY2 ?\b', 'setf'	#certify is not sEtf
    $pronunciation = $pronunciation -creplace 'S IH1 M P L AH0 F AY2 ?\b', 'sempf'	#simplify is not semplf
    $pronunciation = $pronunciation -creplace 'S T AO1 R AH0 JH ?\b', 'storj'	#storage is not stoj

    # Conditional matches
    if ($word -ne 'bin') {
        $pronunciation = $pronunciation -creplace 'B IH1 N ?\b', 'bn'	#been is not ben
    } else {
        $pronunciation = $pronunciation -creplace 'B IH1 N ?\b', 'ben'	#bin is not ben
    }
    if ($word -cmatch 'wear') {
        $pronunciation = $pronunciation -creplace '^ar', 'uar'	#wear is not ar
    }
    if ($word -cmatch 'are$') {
        $pronunciation = $pronunciation -creplace 'EH1 ?\b', 'a'
    }
    if ($pronunciation -cmatch 'M.*[MN] (EY2 )[TRLMKN]') {
        $pronunciation = $pronunciation -creplace $Matches[1], 'a'
    }
    if ($pronunciation -cmatch 'M.*[MN] (EY2 )[TRLMKN]') {
        $pronunciation = $pronunciation -creplace $Matches[1], 'a'
    }
    if ($pronunciation -cmatch 'M.*[MN] (ER0 )AH0 L') {
        $pronunciation = $pronunciation -creplace $Matches[1], 'er'
    }
    if (($word -notmatch 'ment$') -and ($pronunciation -cmatch 'M.*[MN] (\w\w\d )[TRLMKN]')) {
        $pronunciation = $pronunciation -creplace $Matches[1], 'e'
    }
    if ($pronunciation -cmatch '(Z IH0 T)') {
        $pronunciation = $pronunciation -creplace $Matches[1], 'Z eT'
    }
    if ($word -cmatch 'd$' -and $pronunciation -cmatch 'T$') {
        $pronunciation = $pronunciation -creplace 'T$', 'd'
    }

    # Suffixes
    $pronunciation = $pronunciation -creplace 'F AY2$', 'f'
    $pronunciation = $pronunciation -creplace 'S EH1 L V Z$', 'ss'
    $pronunciation = $pronunciation -creplace 'S EH1 L F$', 's'
    $pronunciation = $pronunciation -creplace 'F AH0 L$', 'f'
    $pronunciation = $pronunciation -creplace 'DH ER\d N$', 'hen'
    $pronunciation = $pronunciation -creplace 'AE1 DH ER\d$', 'ah'
    if ($word -match 'other') {
        $pronunciation = $pronunciation -creplace 'AH1 DH ER0 ?\b', 'uh'
    }
    if ($word -match 'oth') {
        $pronunciation = $pronunciation -creplace 'AA1 DH ER\d$', 'oH'
    }
    $pronunciation = $pronunciation -creplace 'AA1 DH ER\d$', 'aH'
    $pronunciation = $pronunciation -creplace 'DH ER\d$', 'H'

    # Prefixes
    $pronunciation = $pronunciation -creplace '^HH IH0 M ?\b', 'hem'	#him is hem
    $pronunciation = $pronunciation -creplace '^HH ER0 ?\b', 'her'	#her is her
    if ($word -match '^f[ou]r') {
        $pronunciation = $pronunciation -creplace '^F ER\d ?\b', 'f'
    }
    $pronunciation = $pronunciation -creplace '^AW0 ER0 ?\b', 'r'	#our.. is r
    $pronunciation = $pronunciation -creplace '^Y ER0 ?\b', 'u'	#your.. is u
    $pronunciation = $pronunciation -creplace '^Y UH0 R ?\b', 'u'	#your.. is u
    $pronunciation = $pronunciation -creplace '^S EY1 K ?\b', 'sak'	#sake
    $pronunciation = $pronunciation -creplace '^S EY1 K ?\b', 'sak'	#sake
    $pronunciation = $pronunciation -creplace '^S ... K ?\b', 'sek'	#security
    $pronunciation = $pronunciation -creplace '^IH0 K S T ER1 ?\b', 'es'	#external is not estrnl
    $pronunciation = $pronunciation -creplace '^IH\d N T ER1 ?\b', 'n'	#internal is not ntrnl
    $pronunciation = $pronunciation -creplace '^nT ER\d ?\b', 'n'	#internal is not ntrnl
    $pronunciation = $pronunciation -creplace '^AY1 \b', 'a'
    $pronunciation = $pronunciation -creplace '^M IH1 (Z|S) \b', 'ms'
    $pronunciation = $pronunciation -creplace '^R I\w\d ?\b', 'r'
    $pronunciation = $pronunciation -creplace '^A(O|H)\d TH ?', 'oH'
    $pronunciation = $pronunciation -creplace '^D IH1 S ?', 'ds'
    $pronunciation = $pronunciation -creplace '^D EH1 Z ?', 'ds'
    $pronunciation = $pronunciation -creplace '^P R AH0 D ?', 'prod'
    $pronunciation = $pronunciation -creplace '^P R AH0 T ?', 'prot'
    $pronunciation = $pronunciation -creplace '^P R AH0 K ?', 'prok'
    $pronunciation = $pronunciation -creplace '^AH0 N ?[Nn] ?', 'un'
    if ($pronunciation -cmatch '^AH0 N [AEOIU]') {
        $pronunciation = $pronunciation -creplace '^AH0 N ?\b', 'an'
    }
    if ($pronunciation -cmatch '^AH2 N [AEOIU]') {
        $pronunciation = $pronunciation -creplace '^AH2 N ?\b', 'n'
    }
    if ($pronunciation -cmatch '^IH2 N [AEOIU]') {
        $pronunciation = $pronunciation -creplace '^IH2 N ?\b', 'en'
    }
    if ($pronunciation -cmatch '^EH1 M [AEOIU]') {
        $pronunciation = $pronunciation -creplace '^EH1 M ?\b', 'em'
    }
    if ($word -notmatch '^ar[mt]') {
        $pronunciation = $pronunciation -creplace '^AA1 R ?', 'ar' # aria
        $pronunciation = $pronunciation -creplace '^AA1 ?', 'o'
        if ($word -cmatch '^a') {
            $pronunciation = $pronunciation -creplace '^ER0 ?\b', 'ar'
            $pronunciation = $pronunciation -creplace '^EH1 ?\b', 'a'
            $pronunciation = $pronunciation -creplace '^AA1 ?\b', 'a'
        }
    } 
    if ($word -cmatch '^o') {
        $pronunciation = $pronunciation -creplace '^AA2 ?\b', 'o'
    }
    $pronunciation = $pronunciation -creplace '^EH0 M ?\b', 'm'
    $pronunciation = $pronunciation -creplace '^EH1 M ?\b', 'm'
    $pronunciation = $pronunciation -creplace '^EH1 N ?\b', 'n'
    $pronunciation = $pronunciation -creplace '^IH2 N ?\b', 'n'
    $pronunciation = $pronunciation -creplace '^AH0 N ?\b', 'n'
    $pronunciation = $pronunciation -creplace '^IH0 G Z ?\b', 'es'
    $pronunciation = $pronunciation -creplace '^[EI]H. K S ?\b', 'es'
    if ($word -cmatch '^i') {
        $pronunciation = $pronunciation -creplace '^AY0 ?\b', 'a'
    }
    $pronunciation = $pronunciation -creplace '^P ER0 ?\b', 'pr'
    $pronunciation = $pronunciation -creplace '^P R AA1 ?\b', 'pr'
    $pronunciation = $pronunciation -creplace '^AH2 N ?\b', 'n'

    # Counterclockwise vowels
    $straightStrokes = '(H|M|N|T|D|JH|CH|SH|h|m|n|t|d|j|c|z)'
    $forwardStraightStrokes = '(M|N|T|D|m|n|t|d)'
    $horizontalStrokes = '(M|N|G|K|L|R|TH|m|n|g|k|l|r|h)'
    $downwardStrokes = '(S|P|B|F|V|JH|CH|SH|s|p|b|f|v|j|c|z)'
    $upwardStrokes = '(T|N T|N T|D|t|n t|n d|d)'
    $thLeftStrokes = '(O..|R|ER.|L|o|r|l)'
    if ($pronunciation -cmatch "AA1 R T") {
        $pronunciation = $pronunciation -creplace 'AA1 R T ?\b', 'At'
    }
    if ($pronunciation -cmatch "TH ?$thLeftStrokes") {
        $pronunciation = $pronunciation -creplace 'TH ?\b', 'H'
    }
    if ($pronunciation -cmatch "$straightStrokes ?ER1`$") {
        $pronunciation = $pronunciation -creplace 'ER1 ?\b', 'E'
    }
    if (($word -notmatch 'red$') -and ($pronunciation -cmatch "ER1 ?$straightStrokes`$")) {
        $pronunciation = $pronunciation -creplace 'ER1 ?\b', 'E'
    }
    if ($pronunciation -cmatch "$straightStrokes ?ER0`$") {
        $pronunciation = $pronunciation -creplace 'ER0 ?\b', 'E'
    }
    if (($word -notmatch 'red$') -and ($pronunciation -cmatch "ER0 ?$straightStrokes`$")) {
        $pronunciation = $pronunciation -creplace 'ER0 ?\b', 'E'
    }
    if ($pronunciation -cmatch "$straightStrokes ?AA1 R`$") {
        $pronunciation = $pronunciation -creplace 'AA1 R ?\b', 'A'
    }
    if (($word -notmatch 'red$') -and ($pronunciation -cmatch "AA1 R ?$straightStrokes")) {
        $pronunciation = $pronunciation -creplace 'AA1 R ?\b', 'A'
    }
    if ($pronunciation -cmatch "$straightStrokes ?EH1 R`$") {
        $pronunciation = $pronunciation -creplace 'EH1 R ?\b', 'A'
    }
    if (($word -notmatch 'red$') -and ($pronunciation -cmatch "EH1 R ?$straightStrokes")) {
        $pronunciation = $pronunciation -creplace 'EH1 R ?\b', 'A'
    }
    if ($pronunciation -cmatch "$straightStrokes ?IH1 R`$") {
        $pronunciation = $pronunciation -creplace 'IH1 R ?\b', 'E'
    }
    if (($word -notmatch 'red$') -and ($pronunciation -cmatch "IH1 R ?$straightStrokes")) {
        $pronunciation = $pronunciation -creplace 'IH1 R ?\b', 'E'
    }
    if ($pronunciation -cmatch "$downwardStrokes ?ER. ?$forwardStraightStrokes") {
        $pronunciation = $pronunciation -creplace 'ER. ?\b', 'E'
    }
    if ($pronunciation -cmatch "$downwardStrokes ?IH1 R ?$forwardStraightStrokes") {
        $pronunciation = $pronunciation -creplace 'IH1 R ?\b', 'E'
    }
    if ($pronunciation -cmatch "$downwardStrokes ?EH1 R ?$forwardStraightStrokes") {
        $pronunciation = $pronunciation -creplace 'EH1 R ?\b', 'A'
    }
    if ($pronunciation -cmatch "$downwardStrokes ?AA1 R T") {
        $pronunciation = $pronunciation -creplace 'AA1 R T ?\b', 'At'
    }
    if ($pronunciation -cmatch "$downwardStrokes ?AA1 R ?$forwardStraightStrokes") {
        $pronunciation = $pronunciation -creplace 'AA1 R ?\b', 'A'
    }
    if ($pronunciation -cmatch "$downwardStrokes ?A[^O]. R ?$forwardStraightStrokes`$") {
        $pronunciation = $pronunciation -creplace 'A.. R ?\b', 'A'
    }
    if ($pronunciation -cmatch "$horizontalStrokes ?ER. ?$upwardStrokes") {
        $pronunciation = $pronunciation -creplace 'ER. ?\b', 'E'
    }
    if ($pronunciation -cmatch "$horizontalStrokes ?AA. R ?$upwardStrokes") {
        $pronunciation = $pronunciation -creplace 'AA. R ?\b', 'A'
    }
    if ($pronunciation -cmatch "$horizontalStrokes ?EH1 R AH0 ?$upwardStrokes") {
        $pronunciation = $pronunciation -creplace 'EH1 R AH0 ?\b', 'E'
    }
    if ($pronunciation -cmatch "$horizontalStrokes ?EH. R AH0 ?$upwardStrokes") {
        $pronunciation = $pronunciation -creplace 'EH. R AH0 ?\b', 'A'
    }
    if ($pronunciation -cmatch "S ?ER. ?$sraightStrokes") {
        $pronunciation = $pronunciation -creplace 'ER. ?\b', 'E'
    }
        
    # Counterclockwise - too inconsistently applied compared to other words in earlier lessons that
    # could implement this rule. As such, I'll implement only these exceptions
    # $pronunciation = $pronunciation -creplace 'AA1 R ?\b', 'A'
    # $pronunciation = $pronunciation -creplace 'EH1 R ?\b', 'A'
    # $pronunciation = $pronunciation -creplace 'ER1 ?\b', 'E'

    # Consonant vowel blends
    $pronunciation = $pronunciation -creplace 'V Y UW2 ?\b', 'vu'
    $pronunciation = $pronunciation -creplace 'G Y ER0 ?\b', 'gr'
    $pronunciation = $pronunciation -creplace 'K Y ER0 ?\b', 'kr'
    $pronunciation = $pronunciation -creplace 'AO1 R T ?\b', 'ot'
    $pronunciation = $pronunciation -creplace 'AT ?\b', 'ot'
    $pronunciation = $pronunciation -creplace 'oR T ?\b', 'ot'
    $pronunciation = $pronunciation -creplace 'Y UH1 R ?\b', 'r'
    $pronunciation = $pronunciation -creplace 'T EH1 M P T ?\b', 'tmt'
    $pronunciation = $pronunciation -creplace 'T IY1 M ?\b', 'tem'
    $pronunciation = $pronunciation -creplace 'D AY1 N ?\b', 'din'
    $pronunciation = $pronunciation -creplace 'nD IY0 AH0 N ?\b', 'ndean' # indian
    $pronunciation = $pronunciation -creplace 'D IY. [EAI].. M ?\b', 'dm'
    $pronunciation = $pronunciation -creplace 'D IY. [EAI].. N ?\b', 'dn'
    $pronunciation = $pronunciation -creplace 'T [EAI].. M ?\b', 'tm'
    $pronunciation = $pronunciation -creplace 'D [EAI].. M ?\b', 'dm'
    $pronunciation = $pronunciation -creplace 'T [EAI].. N ?\b', 'tn'
    $pronunciation = $pronunciation -creplace 'D [EAI].. N ?\b', 'dn'
    $pronunciation = $pronunciation -creplace 'T IH0 D$', 'td'
    $pronunciation = $pronunciation -creplace 'D IH0 D$', 'dt'
    $pronunciation = $pronunciation -creplace 'IH0 D$', 'd'	
    $pronunciation = $pronunciation -creplace 'ZH ER0 ?\b', 'z'	
    $pronunciation = $pronunciation -creplace 'AY1 Z ?\b', 'iz'
    $pronunciation = $pronunciation -creplace 'K AO2 R ?\b', 'k'
    $pronunciation = $pronunciation -creplace 'EH1 K T ?\b', 'k'
    $pronunciation = $pronunciation -creplace 'P L AO1 R ?\b', 'plr'
    $pronunciation = $pronunciation -creplace 'K AW1 N T ?\b', 'kt'
    $pronunciation = $pronunciation -creplace 'R EH1 K AH0 [NG] ?\b', 'rk'
    $pronunciation = $pronunciation -creplace 'K AH0 N$', 'kn'
    $pronunciation = $pronunciation -creplace 'K AH0 M$', 'km'
    $pronunciation = $pronunciation -creplace 'K AH1 N$', 'kn'
    $pronunciation = $pronunciation -creplace 'K AH1 M$', 'km'
    $pronunciation = $pronunciation -creplace 'K AH0 M P ?\b', 'kP'
    $pronunciation = $pronunciation -creplace 'K AA1 N ?\b', 'k'
    $pronunciation = $pronunciation -creplace 'K AH0 N ?\b', 'k'
    $pronunciation = $pronunciation -creplace 'K AH1 M ?\b', 'k'
    $pronunciation = $pronunciation -creplace 'F AO0 R ?\b', 'f'
    $pronunciation = $pronunciation -creplace 'M [AE]H0 N T ?\b', 'm'
    $pronunciation = $pronunciation -creplace 'D \wH0 D ?\b', 'dt'
    $pronunciation = $pronunciation -creplace 'P AH0 L$', 'p'
    if ($pronunciation -notmatch 'M [EAI]Y1 N') {
        $pronunciation = $pronunciation -creplace 'M \w\w1 [MN] ?\b', 'mn'
    }
    $pronunciation = $pronunciation -creplace 'IH1 NG K ?\b', 'q'
    $pronunciation = $pronunciation -creplace 'AH1 NG K ?\b', 'q'
    $pronunciation = $pronunciation -creplace 'AH1 NG ?\b', 'g'
    $pronunciation = $pronunciation -creplace 'NG K W ?\b', 'q'
    $pronunciation = $pronunciation -creplace 'NG K ?\b', 'q'
    $pronunciation = $pronunciation -creplace 'NG ?\b', 'g'
    # Allow lightly and solely, but kindly and others need to be kie
    if ($word -notmatch 'le?l') {
        $pronunciation = $pronunciation -creplace 'L IY0$', 'e'
    }
    $pronunciation = $pronunciation -creplace 'Y EH1 ?\b', 'ye'
    $pronunciation = $pronunciation -creplace 'Y IY1 ?\b', 'ye'
    $pronunciation = $pronunciation -creplace 'Y AA1 ?\b', 'ya'
    $pronunciation = $pronunciation -creplace 'Y UW1 ?\b', 'eu'
    $pronunciation = $pronunciation -creplace 'Y AO1 ?\b', 'eo'
    $pronunciation = $pronunciation -creplace 'Y OW1 ?\b', 'eo'
    $pronunciation = $pronunciation -creplace 'Y IH1 ?\b', 'ye'
    $pronunciation = $pronunciation -creplace 'Y AH0 N ?\b', 'n'
    # Pick up yarn (Y An) and yard (Y Ad)
    if ($word -cmatch '^yar') {
        $pronunciation = $pronunciation -creplace 'Y A', 'ya'
    }
    $pronunciation = $pronunciation -creplace 'OW1 AH0 M ?\b', 'oem'
    $pronunciation = $pronunciation -creplace 'AH\d M ?\b', 'm'
    $pronunciation = $pronunciation -creplace '^AH\d SH ?\b', 'az'
    $pronunciation = $pronunciation -creplace 'AH\d SH ?\b', 'z'
    $pronunciation = $pronunciation -creplace 'AH1 JH ?\b', 'j'
    $pronunciation = $pronunciation -creplace 'AH1 CH ?\b', 'c'
    $pronunciation = $pronunciation -creplace 'AH1 SH ?\b', 'z'
    $pronunciation = $pronunciation -creplace 'A[WH]1 N ?\b', 'n'
    $pronunciation = $pronunciation -creplace 'AW1 M ?\b', 'm'
    $pronunciation = $pronunciation -creplace 'UW1 M ?\b', 'm'
    $pronunciation = $pronunciation -creplace 'UW1 N ?\b', 'n'
    $pronunciation = $pronunciation -creplace 'Y AH0 B AH0 L ?\b', 'b'
    $pronunciation = $pronunciation -creplace '((AH0)|(EY1))? ?B AH0 L ?\b', 'b'
    $pronunciation = $pronunciation -creplace 'AO1 R ', 'o' # only within a word, never at the end drop the R
    $pronunciation = $pronunciation -creplace 'ER1 ', 'e' # only within a word, never at the end drop the R
        
        

    # Consonant blends
    $pronunciation = $pronunciation -creplace 'T EN ?\b', 'tn'
    $pronunciation = $pronunciation -creplace 'D EN ?\b', 'dn'
    $pronunciation = $pronunciation -creplace 'T ER0 N ?\b', 'tn'
    $pronunciation = $pronunciation -creplace 'D ER0 N ?\b', 'dn'
    $pronunciation = $pronunciation -creplace 'HH ?\b', 'h'
    $pronunciation = $pronunciation -creplace 'M P T ?\b', 'mt'
    if (($pronunciation -cmatch '(OW1)|(AO0)|(AO1)|(L)|(R) ?TH ?\b') -or ($pronunciation -cmatch 'TH ?(R)|(OW1)|(AO0)|(AO1)')) {
        $pronunciation = $pronunciation -creplace 'TH ?\b', 'H'
    }
    if (($pronunciation -cmatch '(OW1)|(AO0)|(AO1)|(L)|(R) ?DH ?\b') -or ($pronunciation -cmatch 'DH (R)|(OW1)|(AO0)|(AO1)')) {
        $pronunciation = $pronunciation -creplace 'DH ?\b', 'H'
    }
    if ($pronunciation -cmatch '(lo) ?TH ?\b') {
        $pronunciation = $pronunciation -creplace 'TH ?\b', 'H'
    }
    $pronunciation = $pronunciation -creplace 'TH ?\b', 'h'
    $pronunciation = $pronunciation -creplace 'CH ?\b', 'c'
    $pronunciation = $pronunciation -creplace 'JH ?\b', 'j'
    $pronunciation = $pronunciation -creplace 'SH ?\b', 'z'
    $pronunciation = $pronunciation -creplace 'ZH ?\b', 'z'
    $pronunciation = $pronunciation -creplace 'DH ?\b', 'h'
    if ($word -cmatch 'x') {
        $pronunciation = $pronunciation -creplace 'K S ?\b', 'x'
    }
    $pronunciation = $pronunciation -creplace 'K W ?\b', 'q'
        
    # vowel consonant combinations
    $pronunciation = $pronunciation -creplace 'ER0 ?\b', 'r'
    $pronunciation = $pronunciation -creplace 'ER1 ?\b', 'r'

    # Dipthongs
    if ($word -cmatch 'oe') {
        $pronunciation = $pronunciation -creplace 'OW1 AH0 ?\b', 'oe'
    }
    $pronunciation = $pronunciation -creplace 'AY1 A[EH]0 ?\b', 'ie'
    $pronunciation = $pronunciation -creplace 'AY1 ER0 ?\b', 'ier'
    $pronunciation = $pronunciation -creplace 'IY[02] AH0 ?\b', 'ea'
    $pronunciation = $pronunciation -creplace 'Y UW0 ?\b', 'u'
    $pronunciation = $pronunciation -creplace 'Y AH0 ?\b', 'u'
    $pronunciation = $pronunciation -creplace 'OY0 ?\b', 'oe'
    $pronunciation = $pronunciation -creplace 'OY1 ?\b', 'oe'
    if ($pronunciation -cmatch '[VF] AW1') {
        $pronunciation = $pronunciation -creplace 'AW1 ?\b', 'au'
    } else {
        $pronunciation = $pronunciation -creplace 'AW1 ?\b', 'ao'
    }

    # core vowels
    $pronunciation = $pronunciation -creplace 'AE0 ?\b', 'a'
    $pronunciation = $pronunciation -creplace 'AE1 ?\b', 'a'
    $pronunciation = $pronunciation -creplace 'AE2 ?\b', 'a'
    $pronunciation = $pronunciation -creplace 'AY1 ?\b', 'i'
    $pronunciation = $pronunciation -creplace 'AY2 ?\b', 'i'
    $pronunciation = $pronunciation -creplace 'EY0 ?\b', ''
    $pronunciation = $pronunciation -creplace 'EY1 ?\b', 'a'
    $pronunciation = $pronunciation -creplace 'EY2 ?\b', 'a'
    $pronunciation = $pronunciation -creplace 'EH0 ?\b', ''
    if ($pronunciation -cmatch 'F EH1 K') {
        $pronunciation = $pronunciation -creplace 'EH1 ?\b', ''
    } elseif ($word -notmatch '(ray)|(ear)|(air)') {
        $pronunciation = $pronunciation -creplace 'EH1 ?\b', 'e'
        $pronunciation = $pronunciation -creplace 'EH2 ?\b', ''
    } else {
        $pronunciation = $pronunciation -creplace 'EH1 ?\b', 'a'
    }
    $pronunciation = $pronunciation -creplace '^IH0 ?\b', 'e'
    $pronunciation = $pronunciation -creplace 'IH0 ?\b', ''
    $pronunciation = $pronunciation -creplace 'IH1 ?\b', 'e'
    $pronunciation = $pronunciation -creplace 'IH2 ?\b', ''
    $pronunciation = $pronunciation -creplace 'IY1 ?\b', 'e'
    $pronunciation = $pronunciation -creplace 'IY2 ?\b', 'e'
    if ($word -cmatch '^o') {
        $pronunciation = $pronunciation -creplace '^AH0 ?\b', 'o'
    }
    $pronunciation = $pronunciation -creplace '^AH0 ?\b', 'a'
    $pronunciation = $pronunciation -creplace '^AO2 ?\b', 'a'
    $pronunciation = $pronunciation -creplace 'AO2 ?\b', 'o'
    if (($word -cmatch 'u') -and ($word -cnotmatch 'e[^r]')) {
        $pronunciation = $pronunciation -creplace 'AH0 ?\b', 'u'
        $pronunciation = $pronunciation -creplace 'UW0 ?\b', 'u'
        $pronunciation = $pronunciation -creplace 'AH1 ?', 'u'
    }
    if ($word -cmatch 'o') {
        #$pronunciation = $pronunciation -creplace 'AO1 ?\b', 'o'
        #$pronunciation = $pronunciation -creplace 'AA1 ?\b', 'o'
        $pronunciation = $pronunciation -creplace 'UW0 ?\b', 'u'
    } 
    $pronunciation = $pronunciation -creplace 'AO0 ?\b', ''
    $pronunciation = $pronunciation -creplace 'AO1 ?\b', 'o'
    $pronunciation = $pronunciation -creplace 'AA1 ?\b', 'o'
    $pronunciation = $pronunciation -creplace 'UW1 ?\b', 'u'
    $pronunciation = $pronunciation -creplace 'UW2 ?\b', 'u'
    $pronunciation = $pronunciation -creplace 'OW1 ?', 'o'
    $pronunciation = $pronunciation -creplace 'AO1 ?\b', 'a'
    $pronunciation = $pronunciation -creplace 'AA0 ?\b', 'o'
    $pronunciation = $pronunciation -creplace 'AA1 ?\b', 'a'
    $pronunciation = $pronunciation -creplace '^AH0 ?\b', 'a'
    $pronunciation = $pronunciation -creplace 'AH0 ?\b', ''
    $pronunciation = $pronunciation -creplace 'AH1 ?\b', ''
    $pronunciation = $pronunciation -creplace 'IY0 ?\b', 'e'
    $pronunciation = $pronunciation -creplace 'OW0 ?\b', 'o'
    $pronunciation = $pronunciation -creplace 'OW1 ?\b', 'o'
    $pronunciation = $pronunciation -creplace 'OW2 ?\b', 'o'
    $pronunciation = $pronunciation -creplace 'UH0 ?\b', ''
    $pronunciation = $pronunciation -creplace 'UH1 ?\b', 'u'
    $pronunciation = $pronunciation -creplace 'UH2 ?\b', ''
    $pronunciation = $pronunciation -creplace 'AW2 ?\b', 'au'
    $pronunciation = $pronunciation -creplace 'AH2 ?\b', ''
    $pronunciation = $pronunciation -creplace 'UW0 ?\b', 'u'
    $pronunciation = $pronunciation -creplace 'AA2 ?\b', ''
    $pronunciation = $pronunciation -creplace 'ER2 ?\b', ''

    # core consonants
    $pronunciation = $pronunciation -creplace 'K ?\b', 'k'
    # Allow ingly to flow through as G
    $pronunciation = $pronunciation -creplace 'G ?\b', 'g'
    if (($word -match 'y$') -and ($pronunciation -cmatch 'g$')) {
        $pronunciation = $pronunciation -creplace 'g$', 'G'
    }
    $pronunciation = $pronunciation -creplace 'R ?\b', 'r'
    $pronunciation = $pronunciation -creplace 'L ?\b', 'l'
    if ($word -notmatch 'quantity') {
        $pronunciation = $pronunciation -creplace 'T ?\b', 't'
    }
    $pronunciation = $pronunciation -creplace 'D ?\b', 'd'
    $pronunciation = $pronunciation -creplace 'N ?\b', 'n'
    $pronunciation = $pronunciation -creplace 'M ?\b', 'm'
    # Allow an ending 'ings' to flow through as S
    $pronunciation = $pronunciation -creplace 'S ?\b', 's'
    if (($word -match 'ings$') -and ($pronunciation -cmatch 's$')) {
        $pronunciation = $pronunciation -creplace 's$', 'S'
    }
    if ($pronunciation -cnotmatch 'kP[^ ]?') {
        # Maintain that all "comp... words maintain the angle between K and P
        $pronunciation = $pronunciation -creplace 'P ?\b', 'p'
    }
    $pronunciation = $pronunciation -creplace 'B ?\b', 'b'
    $pronunciation = $pronunciation -creplace 'F ?\b', 'f'
    $pronunciation = $pronunciation -creplace 'V ?\b', 'v'
    if ($word -notmatch 'z') {
        $pronunciation = $pronunciation -creplace 'Z ?\b', 's' 
    } else {
        $pronunciation = $pronunciation -creplace 'Z ?\b', 'z'
    }
    $pronunciation = $pronunciation -creplace 'W ?\b', 'u'

    $pronunciation
}
