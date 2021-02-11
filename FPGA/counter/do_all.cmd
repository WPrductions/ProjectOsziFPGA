mode 132
rmdir /S /Q work
vlib work
vcom -explicit -93 pulse_gen.vhd      -work work
vcom -explicit -93 ltb_pulse_gen.vhd  -work work
pause
