
<CsoundSynthesizer>
<CsOptions>
-odac:system:playback_ -+rtaudio=jack  -d

</CsOptions>
<CsInstruments>

sr = 44100 
ksmps = 8
nchnls = 6;2
0dbfs = 1

;; Constants
#define IN #1#
#define OUT #-1#

;; Globals
giBaseFreq = 32
giThreshold = 0.15
gkVolume init 0.5
gkBlowerVolume init 0.5
gkBellsVolume init 0.5
gkGamelanVolume init 0.5
gkBreathVolume init 0.5
gkPhase init 0

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
chn_k "blowvolume",1
chn_k "bellvolume",1
chn_k "gamelanvolume",1
chn_k "breathvolume",1
chn_k "rotationspeed",1

chnset 0.2, "speed1"
chnset 0, "rotationspeed"

gkBreath[] init 7


;; instr 0

; start readers for blowingpressure
gindex = 1 


if (nchnls == 6) then
	vbaplsinit 2, 6, -45, 45, 90, 135, -135, -90
else
	vbaplsinit 2, 2, -45, 45
endif

opcode panning, 0,ak ; rotates the sound from the original position using vbap opcode
	asig, istartpan xin
	istartdegree = istartpan*90-45
	kazim init istartdegree
		krotationspeed chnget "rotationspeed"

	kphase phasor krotationspeed
	idirection = (rnd(1) >= 0.5 ) ? 0 : 1
	print idirection ; random for avery note
	if (krotationspeed>0) then
		if (idirection==1) then
			kphase = 1-kphase
		endif
	endif
	
	if (nchnls==6) then
		kazim = istartdegree + kphase*360
		kazim wrap kazim, 0, 360
		;printk 0.25, kazim
		a1,a2,a3,a4,a5,a6 vbap asig, kazim
		outh a1,a2,a3,a4,a5,a6
		
	else
		
		kazim += kphase*180
		kazim mirror kazim, 0, 90
		a1,a2 vbap asig, kazim
		outs a1,a2
	endif
endop

loop1:
	schedule nstrnum("blowReader")+gindex/10,0,-1,gindex
	print gindex
	loop_le gindex, 1, 6, loop1

;; instruments

alwayson "controller"
instr controller ; read channels
	gkVolume port chnget:k("volume"), 0.02
	gkBlowerVolume port chnget:k("blowvolume"), 0.02
	gkBellsVolume port chnget:k("bellvolume"), 0.02			
	gkBreathVolume port chnget:k("breathvolume"), 0.02
	gkGamelanVolume port chnget:k("gamelanvolume"), 0.02
	;gkPhase phasor chnget:k("rotationspeed")
endin

	
instr blowReader
	iblower = p4 ; 1,2,..6
	Schannel sprintf "b%d", iblower
	kbreath chnget Schannel
	gkBreath[iblower] port kbreath, 0.05
	giThreshold = 0.25
	if (trigger(abs(gkBreath[iblower]),giThreshold,0)==1) then ; pressure bigger than limit
		;printk2 gkBreath[iblower]
		event "i", nstrnum("blower")+iblower/10, 0, -1, iblower, (gkBreath[iblower]>0) ? 1 : 0 
	endif
	if (trigger(abs(gkBreath[iblower]),giThreshold,1)==1) then ; pressure lower than limit
		;printk2 gkBreath[iblower]
		turnoff2 nstrnum("blower")+iblower/10, 4,1 
	endif
		
	
endin

instr blower,10
	inumber = p4 ; 3 pairs, first pair 1,2, second 3, 4 etc one pair has close
	inOut = p5 ; 0 - in 1 - out

	ifreq = giBaseFreq * (1+ceil(inumber/2)) ; should be as 2. 3. and 4. harmonic from giBaseFreq
	
	if (inOut == $IN) then 
		ifreq = ( inumber%2==1 ) ? ifreq - 8 : ifreq +8 ; if exhaling, use lower pitch for odd number player and higher pitch for even nubmer player 
	endif
	;print ifreq
	iamp = 0.1 ; TODO: amp puhumistugevusest
	kamp = iamp* abs(gkBreath[inumber])
	kamp port kamp, 1
	aenv linenr kamp, 0.25,1, 0.001
	;kfreq init ifreq
	
		 	
	asig poscil 1, ifreq
	kh1 = 1 - abs(gkBreath[inumber])/2 ; basetone less when harder blowing (as if going to second harmonic)
	kh2 = kamp *3.5  ;* (1+ jspline:k(0.5,0.5,2)) ; add some variation to specter
	;printk2 kh2  
	kh3 = kamp-giThreshold*3 ;* (1+ jspline:k(0.25,0.5,2))
	kh4 = kamp-giThreshold*2.5 ;* (1+ jspline:k(0.2,0.5,2))
	

		
	asig chebyshevpoly asig, 0, kh1, kh2, kh3, kh4, kh4/2
	;anoise butterbp pinkish(2),ifreq*4, ifreq/2
	;anoise butterlp pinkish(1),ifreq*4
	aout = asig* aenv * gkBlowerVolume * gkVolume
	outs aout, aout
endin	

;schedule "bellCascade",0,0,10, 0.5
instr bellCascade, 20
	icount = p4
	imininterval = 0.05
	imaxinterval = 0.25
	; TODO: pan somewhere
	index = 0
	iharmonic random 40,80 ; from basenote giBas
	istartTime = 0
	ipan = p5
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
	aout = asig *aenv * gkBellsVolume * gkVolume
	panning aout, ipan ; take care of rotation 
	;aL, aR pan2 aout, ipan
	;outs aL, aR
endin

; schedule "testBreath",0,3, 0, 1
;

instr testBreath
	iplayer = p4
	ky line p5,p3,p6
	kspeed expseg 0.05, p3/2, p7, p3/2, 0.05
	kx line p8,p3,p9
	inOut = (p6>p5) ? 1 :-1
	chnset ky, "accY1"
	
	chnset kspeed, "speed1"
	chnset kx, "accX1"
	ipan = rnd(1)
	schedule "breathing",0,p3, iplayer, ipan ;inOut
	;outs a1, a2
endin



;schedule 30.1, 0, -1, 1, 1, 
;schedule 30.1, 0, -1, 1, -1
;schedule -30.1, 0, 0, 1, 0

instr breathing, 30
	iplayer = p4 ; 
	;inOut = p5 ; in  1, out -1
	ipan = p5
	
	if (timeinsts()>8) then ; to stop in every case
		turnoff   
	endif
	
	SaccY sprintf "accY%d",iplayer
	SaccX sprintf "accX%d",iplayer
	Speed sprintf "speed%d",iplayer
	ky chnget SaccY ; vertical accelometer from the phone
	ky port ky,0.05,chnget:i(SaccY)
	kx chnget SaccX
	kx limit kx, 0,0.9 ; for any case
	kx port kx,0.05,chnget:i(SaccX)
	kspeed chnget Speed ; is it needed after all? intensity? 
	kspeed port kspeed,0.05,chnget:i(Speed)
	ifreq random 300,400  ;init (inOut==$IN) ? random:i(300,400) : random:i(400,500)
	iband init 100  ; (inOut==$IN) ? random:i(40,50) : random:i(10,20)
	;print ifreq, iband
	; võibolla siiski lubada negatiivne ky - alla liikudes läheb igal juhul madalamaks?
	kfreq =  ifreq + ifreq*ky/2 ;*inOut ; inout negative if breathing out 
	kband = iband - iband*ky*0.9 ; if inhaling, band narrower
	;printk2 kband
	
	ky limit ky,0, 1; for any case
	ispeedThreshold = 0.03 ; when a note on/off is sent
	kamp = (abs(kspeed))*1.5 ;sqrt(abs(kspeed)-ispeedThreshold)/2 ; kspeed min always 0.05  alguls + 0.01
	kamp limit kamp,0, 0.5
	kamp port kamp, 0.2
	;printk2 kamp
	
	asine poscil 0.5, random:i(8,16)*giBaseFreq 	 ; sine tone
	aenv linenr kamp, 0.6, 1,0.001		

	iamp = 4 ; amp sõltuvusse kiirendusest
	asig butterbp pinkish(iamp),kfreq, kband
	aout = (asig*(1-kx) + kx*asine)  *aenv * gkBreathVolume * gkVolume; the more tilted in x direction, the more sine tone in mix
	panning aout, ipan ; take care of rotation 
	;aL, aR pan2 aout, ipan
	;outs aL, aR	
	
endin

;schedule "gamelan",0,10,13,0.5
instr gamelan
	isound = p4 ; 0..3 - 
	Sfile sprintf "gamelan/soundin.%d", p4
	ipan = p5
	asig soundin Sfile
	ifiledur filelen Sfile
	p3 = (ifiledur > 4) ? 4 : ifiledur ; limit to 4 seconds
	p3 *= 1+ birnd(0.2) ; randomly differ the length
	iamp random 0.5, 0.6
	irise random 0.05,0.3
	aenv linen iamp,irise,p3,p3/2
	icutoff = 2000*(1+isound/10) * (1+iamp*2) ; the louder, the higher the cutoff
	print iamp, icutoff, irise
	;asig butterlp asig, icutoff
	; siin vaja mingi eq
	;asig butterhp asig, 100
	aout = asig*aenv* gkGamelanVolume * gkVolume
	panning aout, ipan ; take care of rotation 
	;aL, aR pan2 asig*aenv* gkGamelanVolume * gkVolume , ipan
	;outs aL, aR
endin

; schedule "testSpeaker",0,3,4
instr testSpeaker
	aenv linen 0.1,0.1,p3,0.1
	outch p4, poscil(aenv,1000)
endin

; schedule "testRotation",0,30,0.5
instr testRotation
	ispeed = p4 
	asig vco2 0.1, 1000, 0
	;kazim = phasor(ispeed)*360
	;printk 0.25, kazim
	;a1,a2,a3,a4,a5,a6 vbap asig, kazim
	;outh a1,a2,a3,a4,a5,a6
	panning asig, 0
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
 <width>425</width>
 <height>565</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="nobackground">
  <r>255</r>
  <g>255</g>
  <b>255</b>
 </bgcolor>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>b1</objectName>
  <x>9</x>
  <y>107</y>
  <width>20</width>
  <height>100</height>
  <uuid>{c0ef4f8c-26bc-4cef-9a4c-03285a4298f4}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>-1.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.04000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>b2</objectName>
  <x>35</x>
  <y>107</y>
  <width>20</width>
  <height>100</height>
  <uuid>{d450dd3f-3330-46dd-8d96-301a9e6b1cd3}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>-1.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>-0.04000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>b3</objectName>
  <x>58</x>
  <y>107</y>
  <width>20</width>
  <height>100</height>
  <uuid>{43a3942c-fb74-48d3-889f-53827700cc69}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>-1.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>-0.02000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>b4</objectName>
  <x>84</x>
  <y>107</y>
  <width>20</width>
  <height>100</height>
  <uuid>{df8b3bed-592f-4c39-92f1-85b0a7c1d98c}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>-1.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>-0.02000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>b5</objectName>
  <x>109</x>
  <y>107</y>
  <width>20</width>
  <height>100</height>
  <uuid>{9b01ea71-0b6e-4fc0-8642-9e0c173eb102}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>-1.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.02000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>b6</objectName>
  <x>137</x>
  <y>107</y>
  <width>20</width>
  <height>100</height>
  <uuid>{5ae6c887-beac-40d3-967d-1d06dc92b231}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>-1.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.04000000</value>
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
  <latched>false</latched>
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
  <xValue>0.32142857</xValue>
  <yValue>0.00000000</yValue>
  <type>crosshair</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable group="0" mode="both">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject type="BSBButton" version="2">
  <objectName>button9</objectName>
  <x>7</x>
  <y>10</y>
  <width>78</width>
  <height>38</height>
  <uuid>{81b8cc80-d7d1-4b80-8000-3ead7af62783}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>event</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Gamelan 1</text>
  <image>/</image>
  <eventLine>i "gamelan" 0 1 0</eventLine>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <bsbObject type="BSBButton" version="2">
  <objectName>button9</objectName>
  <x>89</x>
  <y>9</y>
  <width>78</width>
  <height>38</height>
  <uuid>{7c86e2c8-314d-4439-a224-c6904ec8bab0}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>event</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Gamelan 2</text>
  <image>/</image>
  <eventLine>i "gamelan" 0 1 1</eventLine>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <bsbObject type="BSBButton" version="2">
  <objectName>button9</objectName>
  <x>171</x>
  <y>9</y>
  <width>78</width>
  <height>38</height>
  <uuid>{03c44947-fa03-4efc-b5fd-55d79c094473}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>event</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Gamelan 3</text>
  <image>/</image>
  <eventLine>i "gamelan" 0 1 2</eventLine>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <bsbObject type="BSBButton" version="2">
  <objectName>button9</objectName>
  <x>253</x>
  <y>8</y>
  <width>78</width>
  <height>38</height>
  <uuid>{0fa0e5f1-30b9-457f-81bf-6335e1c06ea1}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>event</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Gamelan 4</text>
  <image>/</image>
  <eventLine>i "gamelan" 0 1 3</eventLine>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <bsbObject type="BSBButton" version="2">
  <objectName>button9</objectName>
  <x>7</x>
  <y>51</y>
  <width>78</width>
  <height>38</height>
  <uuid>{61a51924-2ff1-435b-9ddd-de21410579ee}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>event</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Gamelan 10</text>
  <image>/</image>
  <eventLine>i "gamelan" 0 1 10</eventLine>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <bsbObject type="BSBButton" version="2">
  <objectName>button9</objectName>
  <x>89</x>
  <y>50</y>
  <width>78</width>
  <height>38</height>
  <uuid>{fcc58ab5-5dc5-4668-a929-5c99c44e63ea}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>event</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Gamelan 12</text>
  <image>/</image>
  <eventLine>i "gamelan" 0 1 11</eventLine>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <bsbObject type="BSBButton" version="2">
  <objectName>button9</objectName>
  <x>171</x>
  <y>50</y>
  <width>78</width>
  <height>38</height>
  <uuid>{e949f778-4c69-4a9b-9ea0-edb2214d30a7}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>event</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Gamelan 13</text>
  <image>/</image>
  <eventLine>i "gamelan" 0 1 12</eventLine>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <bsbObject type="BSBButton" version="2">
  <objectName>button9</objectName>
  <x>253</x>
  <y>49</y>
  <width>78</width>
  <height>38</height>
  <uuid>{2fde82cb-fb97-49ae-a77f-a36924e69d52}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>event</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Gamelan 14</text>
  <image>/</image>
  <eventLine>i "gamelan" 0 1 13</eventLine>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>volume</objectName>
  <x>195</x>
  <y>107</y>
  <width>20</width>
  <height>100</height>
  <uuid>{a077549f-984b-4c73-a68b-a6724a4eb760}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>10.00000000</maximum>
  <value>2.40000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>176</x>
  <y>213</y>
  <width>51</width>
  <height>24</height>
  <uuid>{897b1d7d-540f-43ae-80bd-4b89a957c7d8}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Master</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>blowvolume</objectName>
  <x>245</x>
  <y>106</y>
  <width>20</width>
  <height>100</height>
  <uuid>{90e5ae38-4286-4c9b-a964-97ffc35aad58}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.31000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>230</x>
  <y>212</y>
  <width>51</width>
  <height>24</height>
  <uuid>{5818734c-2da1-489e-82ec-e970482173a7}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Blower</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>bellvolume</objectName>
  <x>296</x>
  <y>105</y>
  <width>20</width>
  <height>100</height>
  <uuid>{1d7ae36e-5b2d-4a9f-ae26-d24054538a39}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.86000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>285</x>
  <y>210</y>
  <width>45</width>
  <height>26</height>
  <uuid>{a0d974f5-1e69-4f4e-bf2b-92f1ac34ebe6}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Bells</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>breathvolume</objectName>
  <x>342</x>
  <y>105</y>
  <width>20</width>
  <height>100</height>
  <uuid>{4eadf820-5473-434d-9556-94258d32d5e5}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.39000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>331</x>
  <y>210</y>
  <width>45</width>
  <height>26</height>
  <uuid>{b7557cc3-ed9a-4236-9b67-615118ef5104}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Breath</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>gamelanvolume</objectName>
  <x>391</x>
  <y>105</y>
  <width>20</width>
  <height>100</height>
  <uuid>{5b2cd309-993d-4d8b-8336-3ffc238d96b8}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>1.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>380</x>
  <y>210</y>
  <width>45</width>
  <height>26</height>
  <uuid>{3483647d-c2b0-40fe-84e1-d6d673f29da6}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Gamelan</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject type="BSBHSlider" version="2">
  <objectName>rotationspeed</objectName>
  <x>234</x>
  <y>469</y>
  <width>124</width>
  <height>32</height>
  <uuid>{5623a977-a003-49d0-b7b7-21115274ef8a}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.21774194</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>149</x>
  <y>474</y>
  <width>80</width>
  <height>25</height>
  <uuid>{86f1b4b6-f673-4452-a28d-c4a1df778d85}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Rotationspeed</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
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
<EventPanel name="blower" tempo="60.00000000" loop="8.00000000" x="1261" y="597" width="655" height="346" visible="true" loopStart="0" loopEnd="0">i "blower" 0 1 1 0 
i "blower" 0 1 2 0 
    
i "blower" 0 1 3 1 
i "blower" 0 1 4 0 
1    
i "blower" 0 1 5 0 
i "blower" 0 1 6 0 </EventPanel>
<EventPanel name="testBreath" tempo="60.00000000" loop="8.00000000" x="133" y="398" width="655" height="346" visible="false" loopStart="0" loopEnd="0">;       ;.       ;.       ;.       ;player       ;ystart       ;yend       ;speed       ;xstart       ;xend 
i "testBreath" 0 4 1 0 0.9 0.5 0.3 1 
i "testBreath" 0 2 1 0.9 0.1 0.2 0 1 
i "testBreath" 0 2 1 0 0.5 1 0.5 0.8 
i "testBreath" 0 2 1 0.5 0.9 1 1 1 
i "testBreath" 0 0.5 1 0.9 0.3 1.5 1 0 
i "testBreath" 0 2 1 1 0 1 0 0 </EventPanel>
