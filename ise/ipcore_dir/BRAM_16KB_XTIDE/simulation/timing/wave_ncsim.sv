
 
 
 




window new WaveWindow  -name  "Waves for BMG Example Design"
waveform  using  "Waves for BMG Example Design"


      waveform add -signals /BRAM_16KB_XTIDE_tb/status
      waveform add -signals /BRAM_16KB_XTIDE_tb/BRAM_16KB_XTIDE_synth_inst/bmg_port/CLKA
      waveform add -signals /BRAM_16KB_XTIDE_tb/BRAM_16KB_XTIDE_synth_inst/bmg_port/ADDRA
      waveform add -signals /BRAM_16KB_XTIDE_tb/BRAM_16KB_XTIDE_synth_inst/bmg_port/ENA
      waveform add -signals /BRAM_16KB_XTIDE_tb/BRAM_16KB_XTIDE_synth_inst/bmg_port/DOUTA
console submit -using simulator -wait no "run"
