Auto-adjusting scheme for Neovim
################################

This is a WIP repository of a colorscheme that can autoadjust to current
terminal colors.

It is written with ConEmu for Windows terminal emulator, which I use in 16
colors mode. So, I'd like to have a colorscheme, that selects appropriate
colors from a specified palette and assigns them to highlight groups.

I have borrowed a big part of colorscheme code from someone, but I forgot
where, so I cannot credit him, sorry.

Additionally, it uses `colors.lua <http://sputnik.freewisdom.org/lib/colors>`_
library for sorting colors.

The scheme gets color groups by sorting and filtering the palette by hue,
saturation, lightness, red, green and blue and selects appropriate colors,
then assigns the selected colors to groups (which can consist of 1 color too).
Then the function chooses one of the colors in the group randomly. So, colors
may slightly change after restart, which is OK for me for now.

As said, this is WIP, and for now is tested on OneDark color scheme for
ConEmu.
