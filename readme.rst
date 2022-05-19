Auto-adjusting scheme for Neovim
################################

This is a WIP repository of a colorscheme that can autoadjust to current
terminal color scheme (which you have to pass to the plugin anyway).

It is written with ConEmu for Windows terminal emulator, which I use in 16
colors mode (see the `transform` function). So, I'd like to have
a colorscheme, that selects appropriate colors from a specified palette and
assigns them to highlight groups.

I have borrowed a big part of colorscheme code from `lvim-tech <https://github.com/lvim-tech/lvim-colorscheme>`_.

Additionally, it uses `colors.lua <http://sputnik.freewisdom.org/lib/colors>`_
library for sorting colors.

The scheme gets color groups by sorting and filtering the palette by hue,
saturation, lightness, etc. and selects appropriate colors, then assigns the
selected colors to groups (which can consist of 1 or more colors). Then the
function chooses one of the colors in the group randomly. So, colors may
slightly change after restart, which is OK for me for now.

As said, this is WIP, and for now is tested on OneDark color scheme for ConEmu
(I cannot link to the source I found it; rip this colorscheme from
`lua\glitter.lua` if you want. It can load another color scheme, which you
pass to the setup function in `colors/glitter.vim` as `setup({ {0, '#000000'},
{1, '#cccccc'} …})`, passing a list of colors with their number in ConEmu
palette and RRGGBB string value.

Obviously enough, colorschemes vary significantly in colors variability, so
the plugin in the committed state works nicely only if colorschemes passed are
similiar: have one or two dark colors, a few highlights etc., otherwise you'll
have to change the rules in `lua\glitter.lua`.

Usage
*****

* Pass the required palette to `setup()` function in `./colors/glitter.vim`;
* Set the required palette in ConEmu task paramaters
  `-new_console:P:"Palette"` in tab context menu;
* ``colorscheme glitter``.

Edit ``glitter.lua`` to set required palette selection rules.
