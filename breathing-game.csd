/*
pillid

puhkpillid - 3 paari, ühes paaris välja +/-16 HZ, sisse 0; sagedused: Base=128 base, 1.5*base, 2*base

telefonid/app - hingamine - ribafiltri sahin, sagedused 32 HZ osahelid; telfeno külili - rohkem tooni ? filtri laius vm tooni

veebiäpp - gamelani moodi klajvid; tähesadu valitud suunas (vt. reso_game) 
*/

<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>

sr = 44100 
ksmps = 32
nchnls = 2
0dbfs = 1

;; Constants
#define IN #0#
#define OUT #1#

;; Globals
giBaseFreq = 32
giThreshold = 0.25

;; Channels
chn_k "b1",3
chn_k "b2",3
chn_k "b3",3
chn_k "b4",3
chn_k "b5",3
chn_k "b6",3

gSbreather[] fillarray "b1", "b2", "b3", "b4", "b5", "b6"
gkBreath[] init 7

gindex = 1 ; start readers for blowingpressure
loop1:
	schedule nstrnum("blowReader")+gindex/10,0,-1,gindex
	print gindex
	loop_le gindex, 1, 6, loop1
	
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

instr blower
	inumber = p4 ; 3 pairs, first pair 1,2, second 3, 4 etc one pair has close
	inOut = p5 ; 0 - in 1 - ou
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
		

</CsInstruments>
<CsScore>

</CsScore>
</CsoundSynthesizer>

<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>0</x>
 <y>0</y>
 <width>158</width>
 <height>183</height>
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
  <value>-0.32000000</value>
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
  <value>-0.30000000</value>
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
  <value>-0.44000000</value>
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
  <value>-0.90000000</value>
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
  <value>-0.60000000</value>
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
  <value>0.78000000</value>
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
<EventPanel name="" tempo="60.00000000" loop="8.00000000" x="1261" y="597" width="655" height="346" visible="false" loopStart="0" loopEnd="0">i "blower" 0 1 1 0 
i "blower" 0 1 2 0 
    
i "blower" 0 1 3 1 
i "blower" 0 1 4 0 
1    
i "blower" 0 1 5 0 
i "blower" 0 1 6 0 </EventPanel>
