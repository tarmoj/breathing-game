/*
pillid

puhkpillid - 3 paari, ühes paaris välja +/-16 HZ, sisse 0; sagedused: Base=128 base, 1.5*base, 2*base

telefonid/app - hingamine - ribafiltri sahin, sagedused 32 HZ osahelid; telfeno külili - rohkem tooni ? filtri laius vm tooni

veebiäpp - gamelani moodi klajvid; tähesadu valitud suunas (vt. reso_game) 
*/

<CsoundSynthesizer>
<CsOptions>
-odac:system:playback_ -+rtaudio=jack  -d
</CsOptions>
<CsInstruments>

sr = 44100 
ksmps = 32
nchnls = 2
0dbfs = 1

;; Constants
#define IN #1#
#define OUT #-1#

;; Globals
giBaseFreq = 32
giThreshold = 0.25
gkVolume init 0.5

seed 0

;; Channels
chn_k "b1",3
chn_k "b2",3
chn_k "b3",3
chn_k "b4",3
chn_k "b5",3
chn_k "b6",3

chn_k "accX1",1
chn_k "accY1",1
chn_k "speed1",1

chn_k "volume",1

chnset 0.2, "speed1"

gSbreather[] fillarray "b1", "b2", "b3", "b4", "b5", "b6"
gkBreath[] init 7

gindex = 1 ; start readers for blowingpressure
loop1:
	schedule nstrnum("blowReader")+gindex/10,0,-1,gindex
	print gindex
	loop_le gindex, 1, 6, loop1

alwayson "controller"
instr controller
	gkVolume chnget "volume"
	printk2 gkVolume
endin
	
instr blowReader
	iblower = p4 ; 1,2,..6
	Schannel sprintf "b%d", iblower
	gkBreath[iblower] chnget Schannel
	giThreshold = 0.25
	if (trigger(abs(gkBreath[iblower]),giThreshold,0)==1) then ; pressure bigger than limit
		printk2 gkBreath[iblower]
		event "i", nstrnum("blower")+iblower/10, 0, -1, iblower, (gkBreath[iblower]>0) ? 1 : 0 
	endif
	if (trigger(abs(gkBreath[iblower]),giThreshold,1)==1) then ; pressure lower than limit
		printk2 gkBreath[iblower]
		turnoff2 nstrnum("blower")+iblower/10, 4,1 
	endif
		
	
endin

instr blower,10
	inumber = p4 ; 3 pairs, first pair 1,2, second 3, 4 etc one pair has close
	inOut = p5 ; 0 - in 1 - out
	; TODO: kui puhub kõvemini, siis mine järgmise osaheli peale (paarituarvulised?)
	ifreq = giBaseFreq * (1+ceil(inumber/2)) ; should be as 2. 3. and 4. harmonic from giBaseFreq
	
	if (inOut == $IN) then 
		ifreq = ( inumber%2==1 ) ? ifreq - 8 : ifreq +8 ; if exhaling, use lower pitch for odd number player and higher pitch for even nubmer player 
	endif
	print ifreq
	iamp = 0.1 ; TODO: amp puhumistugevusest
	kamp = iamp* port(abs(gkBreath[inumber]),0.02,abs(i(gkBreath[inumber])) )
	aenv linenr kamp, 0.25,0.5, 0.001
	asig poscil 1, ifreq; TODO: later chebyshev
	kh2 = kamp *3  * (1+ jspline:k(0.5,0.5,2))
	;printk2 kh2  
	kh3 = kamp-giThreshold*2.5 * (1+ jspline:k(0.25,0.5,2))
	kh4 = kamp-giThreshold*2 * (1+ jspline:k(0.2,0.5,2))
	asig chebyshevpoly asig, 0, 1, kh2, kh3, kh4
	;anoise butterbp pinkish(2),ifreq*4, ifreq/2
	;anoise butterlp pinkish(1),ifreq*4
	aout = asig* aenv 
	outs aout, aout
endin	

;schedule "bellCascade",0,0,10
instr bellCascade, 20
	icount = p4
	imininterval = 0.05
	imaxinterval = 0.25
	; TODO: pan somewhere
	index = 0
	iharmonic random 40,80 ; from basenote giBas
	istartTime = 0
	ipan random 0,1
loop2:
	iharmonic -= int(random:i(1,4)) ; lower harmoniv with every time, but with random intervals
	ifreq = giBaseFreq * iharmonic
	iduration random 1.5,3
	
	schedule "bell",istartTime,iduration, ifreq, ipan
	istartTime += random:i(imininterval,imaxinterval)
	loop_lt index,1,icount,loop2 
	 
		
endin
		
; schedule "bell",0,2,548, 1.25, 0.75
instr bell
	iamp random 0.02,0.005
	aenv linen iamp,0.01,p3,p3/2
	ivibrdepth random 0.005,0.01
	ivibrrate random 2,6
	ifreq = p4
	ipan = p5
	ic1 random 0.5,1
	ic2 random 0.5,1
	;print ic1, ic2, ivibrdepth, ivibrrate
	asig fmbell 1, ifreq, ic1, ic2, ivibrdepth, ivibrrate, -1, -1, -1, -1, -1
	asig butterlp asig, random:i(1000,2000)
	aout = asig *aenv
	aL, aR pan2 aout, ipan
	outs aL, aR
endin

; schedule 30.1, 0, 2, 1, 1
; schedule 30.1, 0,2, 1, -1


;schedule 30.1, 0, -1, 1, 1
;schedule 30.1, 0, -1, 1, -1
;schedule -30.1, 0, 0, 1, 0

instr breathing, 30
	iplayer = p4 ; 
	inOut = p5 ; in  1, out -1
	SaccY sprintf "accY%d",iplayer
	SaccX sprintf "accX%d",iplayer
	Speed sprintf "speed%d",iplayer
	ky chnget SaccY ; vertical accelometer from the phone
	kx chnget SaccX
	kspeed chnget Speed ; is it needed after all? intensity? 
	ifreq random 300,400  ;init (inOut==$IN) ? random:i(300,400) : random:i(400,500)
	iband init 100  ; (inOut==$IN) ? random:i(40,50) : random:i(10,20)
	print ifreq, iband
	; võibolla siiski lubada negatiivne ky - alla liikudes läheb igal juhul madalamaks?
	kfreq =  ifreq + ifreq*ky/2 ;*inOut ; inout negative if breathing out 
	kband = iband - iband*ky*0.9 ; if inhaling, band narrower
	printk2 kband
	
	kamp  = 0.1 ;+ ky ;* (1 + abs(kspeed))
	aenv linenr kamp, 0.3, 0.2,0.001	
	; TODO: port!
	
	
;	if (inOut==$IN) then
		
;		kfreq line random:i(300,400),p3,random:i(400,500)
;		kband line 40,p3,10
;		aenv expsegr 0.0001, 0.5, 0.05, 4,1,1,0.001
;	else
;		kfreq line random:i(400,500),p3,random:i(300,400)
;		kband line 10,p3,40
;		aenv linsegr 0.0001, 1, 0.5, 2,0.001
;	endif
	iamp = 4 ; amp sõltuvusse kiirendusest
	
	asig butterbp pinkish(iamp),kfreq, kband
	aout = asig*aenv
	outs aout, aout	
	
endin




</CsInstruments>
<CsScore>

</CsScore>
</CsoundSynthesizer>



<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>0</x>
 <y>0</y>
 <width>357</width>
 <height>431</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="nobackground">
  <r>255</r>
  <g>255</g>
  <b>255</b>
 </bgcolor>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>b1</objectName>
  <x>10</x>
  <y>83</y>
  <width>20</width>
  <height>100</height>
  <uuid>{c0ef4f8c-26bc-4cef-9a4c-03285a4298f4}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>-1.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>-0.56000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>b2</objectName>
  <x>36</x>
  <y>83</y>
  <width>20</width>
  <height>100</height>
  <uuid>{d450dd3f-3330-46dd-8d96-301a9e6b1cd3}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>-1.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>-0.76000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>b3</objectName>
  <x>59</x>
  <y>83</y>
  <width>20</width>
  <height>100</height>
  <uuid>{43a3942c-fb74-48d3-889f-53827700cc69}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>-1.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>-0.62000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>b4</objectName>
  <x>85</x>
  <y>83</y>
  <width>20</width>
  <height>100</height>
  <uuid>{df8b3bed-592f-4c39-92f1-85b0a7c1d98c}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>-1.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>-0.56000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>b5</objectName>
  <x>110</x>
  <y>83</y>
  <width>20</width>
  <height>100</height>
  <uuid>{9b01ea71-0b6e-4fc0-8642-9e0c173eb102}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>-1.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>-0.62000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>b6</objectName>
  <x>138</x>
  <y>83</y>
  <width>20</width>
  <height>100</height>
  <uuid>{5ae6c887-beac-40d3-967d-1d06dc92b231}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>-1.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>-0.80000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBScope" version="2">
  <objectName>scope</objectName>
  <x>7</x>
  <y>281</y>
  <width>350</width>
  <height>150</height>
  <uuid>{688aa736-3229-45b1-a511-41302503e48a}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <value>-255.00000000</value>
  <type>scope</type>
  <zoomx>2.00000000</zoomx>
  <zoomy>3.00000000</zoomy>
  <dispx>1.00000000</dispx>
  <dispy>1.00000000</dispy>
  <mode>0.00000000</mode>
 </bsbObject>
 <bsbObject type="BSBButton" version="2">
  <objectName>button7</objectName>
  <x>8</x>
  <y>223</y>
  <width>100</width>
  <height>30</height>
  <uuid>{b3670a8b-0892-4cf2-bfe8-f520edf34312}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>event</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Bells</text>
  <image>/</image>
  <eventLine>i "bellCascade" 0 0 10</eventLine>
  <latch>false</latch>
  <latched>true</latched>
 </bsbObject>
 <bsbObject type="BSBController" version="2">
  <objectName>accX1</objectName>
  <x>26</x>
  <y>459</y>
  <width>112</width>
  <height>106</height>
  <uuid>{fc17a7ea-fbbd-4cef-b593-9d61f9db1653}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <objectName2>accY1</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.37500000</xValue>
  <yValue>0.58490566</yValue>
  <type>crosshair</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
</bsbPanel>
<bsbPresets>
<preset name="mute" number="0" >
<value id="{c0ef4f8c-26bc-4cef-9a4c-03285a4298f4}" mode="1" >-0.04000000</value>
<value id="{d450dd3f-3330-46dd-8d96-301a9e6b1cd3}" mode="1" >-0.02000000</value>
<value id="{43a3942c-fb74-48d3-889f-53827700cc69}" mode="1" >-0.02000000</value>
<value id="{df8b3bed-592f-4c39-92f1-85b0a7c1d98c}" mode="1" >-0.02000000</value>
<value id="{9b01ea71-0b6e-4fc0-8642-9e0c173eb102}" mode="1" >-0.06000000</value>
<value id="{5ae6c887-beac-40d3-967d-1d06dc92b231}" mode="1" >-0.06000000</value>
</preset>
</bsbPresets>
<EventPanel name="" tempo="60.00000000" loop="8.00000000" x="1261" y="597" width="655" height="346" visible="true" loopStart="0" loopEnd="0">i "blower" 0 1 1 0 
i "blower" 0 1 2 0 
    
i "blower" 0 1 3 1 
i "blower" 0 1 4 0 
1    
i "blower" 0 1 5 0 
i "blower" 0 1 6 0 </EventPanel>
