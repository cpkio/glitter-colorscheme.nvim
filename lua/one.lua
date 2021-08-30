-- vim:tabstop=4
local colors = require('colors')

local one = {}

one.palette = {
	{0, '#282c34'},
	{1, '#61afef'},
	{2, '#98c379'},
	{3, '#56b6c2'},
	{4, '#d19a66'},
	{5, '#c678dd'},
	{6, '#e5c07b'},
	{7, '#5c6370'},
	{8, '#2c323c'},
	{9, '#528bff'},
	{10, '#181a1f'},
	{11, '#3e4452'},
	{12, '#e06c75'},
	{13, '#be5046'},
	{14, '#e2f9fc'},
	{15, '#abb2bf'},
  -- none = { -1, "NONE"}
}

function clone(t)
	local u = setmetatable({}, getmetatable(t))
	for i, v in pairs(t) do
		u[i] = v
	end
	return u
end
function one.transform (tbl)
	for _,item in ipairs(tbl) do
		if item[1] == 1 then item[1] = 4
		elseif item[1] == 3 then item[1] = 6
		elseif item[1] == 4 then item[1] = 1
		elseif item[1] == 6 then item[1] = 3
		elseif item[1] == 9 then item[1] = 12
		elseif item[1] == 11 then item[1] = 14
		elseif item[1] == 12 then item[1] = 9
		elseif item[1] == 14 then item[1] = 11 end
	end
end

local margin = 4

-- Let's introduce parameters for color selection
-- @saturation_threshold means everything below that is «grayish»
local saturation_threshold = 0.25

-- @lightness_threshold means everything up from that is considered light, and
-- vice versa
local lightness_threshold = 0.48

-- @hue_spread means color distance between colors
-- Has to be calculated with lightness in mind
local hue_spread = 40

local colourful_threshold = 0.17


--[[
-- Получать нужные цвета или их пары нужно по следующим схемам:
-- Обычный текст: нейтральный, а значит отбираем цвета
-- - не насыщенные (в соответствии с @saturation_threshold);
-- - сортируем их по светимости и отбираем не самый яркий для фона;
-- - для текста берём верхние по яркости и отбираем наименее цветистый
]]

---------------------------------------------
-- SORT BY HUE
---------------------------------------------
function sort_by_hue(e1, e2)
	local h1, s1, l1 = colors.rgb_string_to_hsl(e1[2])
	local h2, s2, l2 = colors.rgb_string_to_hsl(e2[2])
	return h1 < h2, h1, h2
end

---------------------------------------------
-- SORT BY LIGNTNESS
---------------------------------------------
function sort_by_light_asc(e1, e2)
	local h1, s1, l1 = colors.rgb_string_to_hsl(e1[2])
	local h2, s2, l2 = colors.rgb_string_to_hsl(e2[2])
	return l1 < l2, l1, l2
end

function sort_by_light_dec(e1, e2)
	local h1, s1, l1 = colors.rgb_string_to_hsl(e1[2])
	local h2, s2, l2 = colors.rgb_string_to_hsl(e2[2])
	return l1 > l2, l1, l2
end

---------------------------------------------
-- SORT BY SATURATION
---------------------------------------------
function sort_by_sat_asc(e1, e2)
	local h1, s1, l1 = colors.rgb_string_to_hsl(e1[2])
	local h2, s2, l2 = colors.rgb_string_to_hsl(e2[2])
	return s1 < s2, s1, s2
end

function sort_by_sat_dec(e1, e2)
	local h1, s1, l1 = colors.rgb_string_to_hsl(e1[2])
	local h2, s2, l2 = colors.rgb_string_to_hsl(e2[2])
	return s1 > s2, s1, s2
end

---------------------------------------------
-- SORT BY RED COLOR
---------------------------------------------
function sort_by_red_asc(e1, e2)
	local r1, g1, b1 = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e1[2]))
	local r2, g2, b2 = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e2[2]))
	return r1 < r2, r1, r2
end

function sort_by_red_dec(e1, e2)
	local r1, g1, b1 = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e1[2]))
	local r2, g2, b2 = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e2[2]))
	return r1 > r2, r1, r2
end

---------------------------------------------
-- SORT BY GREEN COLOR
---------------------------------------------
function sort_by_green_asc(e1, e2)
	local r1, g1, b1 = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e1[2]))
	local r2, g2, b2 = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e2[2]))
	return g1 < g2, g1, g2
end

function sort_by_green_dec(e1, e2)
	local r1, g1, b1 = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e1[2]))
	local r2, g2, b2 = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e2[2]))
	return g1 > g2, g1, g2
end

---------------------------------------------
-- SORT BY BLUE COLOR
---------------------------------------------
function sort_by_blue_asc(e1, e2)
	local r1, g1, b1 = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e1[2]))
	local r2, g2, b2 = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e2[2]))
	return b1 < b2, b1, b2
end

function sort_by_blue_dec(e1, e2)
	local r1, g1, b1 = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e1[2]))
	local r2, g2, b2 = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e2[2]))
	return b1 > b2, b1, b2

end

---------------------------------------------
-- GET "MOST" COLOR
---------------------------------------------
-- DARK
darkest = function()
	table.sort(one.palette, sort_by_light_asc)
	return one.palette[1]
end

most_dark = function()
	table.sort(one.palette, sort_by_light_asc)
	return one.palette[2]
end

mostly_dark = function()
	table.sort(one.palette, sort_by_light_asc)
	return one.palette[3]
end

-- LIGHT
brightest = function()
	table.sort(one.palette, sort_by_light_dec)
	return one.palette[1]
end

most_bright = function()
	table.sort(one.palette, sort_by_light_dec)
	return one.palette[2]
end

mostly_bright = function()
	table.sort(one.palette, sort_by_light_dec)
	return one.palette[3]
end

-- SATURATION MOST
colorish = function()
	table.sort(one.palette, sort_by_sat_dec)
	return one.palette[1]
end

most_colorish = function()
	table.sort(one.palette, sort_by_sat_dec)
	return one.palette[2]
end

mostly_colorish = function()
	table.sort(one.palette, sort_by_sat_dec)
	return one.palette[3]
end

-- SATURATION LAST
greyish = function()
	table.sort(one.palette, sort_by_sat_asc)
	return one.palette[1]
end

most_greyish = function()
	table.sort(one.palette, sort_by_sat_asc)
	return one.palette[2]
end

mostly_greyish = function()
	table.sort(one.palette, sort_by_sat_asc)
	return one.palette[3]
end

-- RED
reddest = function()
	table.sort(one.palette, sort_by_red_dec)
	return one.palette[1]
end

most_red = function()
	table.sort(one.palette, sort_by_red_dec)
	return one.palette[2]
end

mostly_red = function()
	table.sort(one.palette, sort_by_red_dec)
	return one.palette[3]
end

-- GREEN
greenest = function()
	table.sort(one.palette, sort_by_green_dec)
	return one.palette[1]
end

most_green = function()
	table.sort(one.palette, sort_by_green_dec)
	return one.palette[2]
end

mostly_green = function()
	table.sort(one.palette, sort_by_green_dec)
	return one.palette[3]
end

-- BLUE
bluest = function()
	table.sort(one.palette, sort_by_blue_dec)
	return one.palette[1]
end

most_blue = function()
	table.sort(one.palette, sort_by_blue_dec)
	return one.palette[2]
end

mostly_blue = function()
	table.sort(one.palette, sort_by_blue_dec)
	return one.palette[3]
end

top_blue = function()
	local result = {}
	table.sort(one.palette, sort_by_blue_dec)
	for i = 1, margin do table.insert(result, one.palette[i]) end
	return result
end

-- Take center part of a sorted palette: minus @margin from top and from bottom
function trim(tbl, sorter, margin)
	local result = {}
	table.sort(tbl, sorter)
	for i = margin + 1, #tbl - margin do table.insert(result, tbl[i]) end
	return result
end

function slice(tbl, sorter, length)
	local result = {}
	if length > #tbl then length = #tbl end
	for i = 1, length do table.insert(result, tbl[i]) end
	return result
end

function normalize(tbl, fun)
	result = clone(tbl)
	table.sort(result, fun)
	local _, min, _ = fun(result[1], result[#result])
	local _, _, max = fun(result[1], result[#result])
	if min > max then
		local _t = min
		min = max; max = _t
	end
	for i, _ in ipairs(result) do
	local _, value, _ = fun(result[i], result[#result])
		result[i][3] = (value-min)/(max-min)
	end
	return result
end

function select_dark(item)
	local _, _, l = colors.rgb_string_to_hsl(item[2])
	return l <= lightness_threshold
end

function select_light(item)
	local _, _, l = colors.rgb_string_to_hsl(item[2])
	return l >= lightness_threshold * 1.3
end

function select_dull(item)
	local _, s, _ = colors.rgb_string_to_hsl(item[2])
	return s <= colourful_threshold
end

function select_colourfull(item)
	local _, s, _ = colors.rgb_string_to_hsl(item[2])
	return s >= colourful_threshold
end

function filter(tbl, ...)
	local result = clone(tbl)
	for _, fn in ipairs({...}) do
	::restart::
		for i, item in ipairs(result) do
			if not fn(item) then table.remove(result, i); goto restart end
		end
	end
	return result
end

function print_colors(tbl, text)
  print(text)
  for _, sub in ipairs(tbl) do
	  local h1, s1, l1 = colors.rgb_string_to_hsl(sub[2])
	  print(string.format("%s | %.2f | %.2f | %.2f | w:%.2f", sub[2], h1, s1, l1, sub[3]))
  end
end

function one.highlight(group, color)
	local style = color.style and "gui=" .. color.style or "gui=NONE"
	local fg = color.fg and "ctermfg=" .. color.fg[1] .. " guifg=" .. color.fg[2] or "guifg=NONE"
	local bg = color.bg and "ctermbg=" .. color.bg[1] .. " guibg=" .. color.bg[2] or "guibg=NONE"
	local sp = color.sp and "guisp=" .. color.sp or ""
	vim.api.nvim_command("highlight " .. group .. " " .. style .. " " .. fg .. " " .. bg .. " " .. sp)
end

function one.load_syntax()
	local syntax = {
		Normal =	{fg = normalize(filter(one.palette, select_light), sort_by_light_dec)[2], bg = normalize(filter(one.palette, select_dark), sort_by_light_asc)[2]},
		-- Terminal =	{fg = lvim.fg, bg = lvim.bg},
		-- SignColumn =	{fg = mostly_dark(), bg = mostly_light()},
		-- FoldColumn =			{fg = lvim.color_10, bg = lvim.black},
		-- VertSplit =	{fg = lvim.black, bg = lvim.bg},
		-- Folded =	{fg = lvim.color_12, bg = lvim.bg_highlight},
		-- EndOfBuffer =			{fg = lvim.bg, bg = lvim.none},
		-- IncSearch =	{fg = lvim.base0, bg = lvim.color_13, style = lvim.none},
		-- Search =	{fg = lvim.base0, bg = lvim.color_13},
		-- ColorColumn =			{fg = lvim.none, bg = lvim.bg_highlight},
		-- Conceal =	{fg = lvim.color_12, bg = lvim.none},
		-- Cursor =	{fg = lvim.none, bg = lvim.none, style = "reverse"},
		-- vCursor =	{fg = lvim.none, bg = lvim.none, style = "reverse"},
		-- iCursor =	{fg = lvim.none, bg = lvim.none, style = "reverse"},
		-- lCursor =	{fg = lvim.none, bg = lvim.none, style = "reverse"},
		-- CursorIM =	{fg = lvim.none, bg = lvim.none, style = "reverse"},
		-- CursorColumn =			{fg = lvim.none, bg = lvim.bg_highlight},
		-- CursorLine =			{fg = lvim.none, bg = lvim.bg_highlight},
		-- LineNr =	{fg = filter(one.palette, select_light)[2]},
		-- qfLineNr =	{fg = lvim.color_10},
		-- CursorLineNr =			{fg = lvim.color_10},
		-- DiffAdd =	{fg = lvim.black, bg = lvim.color_6},
		-- DiffChange =			{fg = lvim.black, bg = lvim.color_3},
		-- DiffDelete =			{fg = lvim.black, bg = lvim.color_0},
		-- DiffText =	{fg = lvim.black, bg = lvim.fg},
		-- Directory =	{fg = lvim.color_8, bg = lvim.none},
		-- ErrorMsg =	{fg = lvim.color_error, bg = lvim.none},
		-- WarningMsg =			{fg = lvim.color_warning, bg = lvim.NONE},
		-- ModeMsg =	{fg = lvim.color_6, bg = lvim.none},
		-- FocusedSymbol =			{fg = lvim.color_5},
		-- MatchParen =			{fg = filter(one.palette, select_light)[1]},
		-- NonText =	{fg = lvim.bg1},
		-- Whitespace =			{fg = lvim.base2},
		-- SpecialKey =			{fg = lvim.bg1},
		-- Pmenu =		{fg = lvim.color_10, bg = lvim.base2},
		-- PmenuSel =	{fg = lvim.base0, bg = lvim.color_10},
		-- PmenuSelBold =			{fg = lvim.base0, bg = lvim.color_10},
		-- PmenuSbar =	{fg = lvim.none, bg = lvim.base2},
		-- PmenuThumb =			{fg = lvim.color_9, bg = lvim.color_4},
		-- WildMenu =	{fg = lvim.color_10, bg = lvim.color_5},
		-- Question =	{fg = lvim.color_3},
		-- NormalFloat =			{fg = lvim.bg_visual, bg = lvim.base2},
		-- Tabline =	{fg = lvim.color_10, bg = lvim.none},
		-- TabLineFill =			{style = lvim.none},
		-- TabLineSel =			{fg = lvim.bg1, bg = lvim.none},
		-- StatusLine =			{fg = lvim.color_13, bg = lvim.base2, style = lvim.none},
		-- StatusLineNC =			{fg = lvim.color_12, bg = lvim.base2, style = lvim.none},
		-- SpellBad =	{fg = lvim.color_0, bg = lvim.none, style = "undercurl"},
		-- SpellCap =	{fg = lvim.color_8, bg = lvim.none, style = "undercurl"},
		-- SpellLocal =			{fg = lvim.color_7, bg = lvim.none, style = "undercurl"},
		-- SpellRare =	{fg = lvim.color_9, bg = lvim.none, style = "undercurl"},
		-- Visual =	{fg = lvim.color_12, bg = lvim.black},
		-- VisualNOS =	{fg = lvim.color_12, bg = lvim.black},
		-- QuickFixLine =			{fg = lvim.color_9},
		-- Debug =		{fg = lvim.color_2},
		-- debugBreakpoint =		{fg = lvim.bg, bg = lvim.color_0},
		-- Boolean =	{fg = lvim.color_2},
		-- Number =	{fg = lvim.color_13},
		-- Float =		{fg = lvim.color_13},
		-- PreProc =	{fg = lvim.color_9},
		-- PreCondit =	{fg = lvim.color_9},
		-- Include =	{fg = lvim.color_9},
		-- Define =	{fg = lvim.color_3},
		-- Conditional =			{fg = lvim.color_5},
		-- Repeat =	{fg = lvim.color_10},
		-- Keyword =	{fg = lvim.color_2},
		-- Typedef =	{fg = lvim.color_0},
		-- Exception =	{fg = lvim.color_0},
		-- Statement =	{fg = lvim.color_0},
		-- Error =		{fg = lvim.color_error},
		-- StorageClass =			{fg = lvim.color_2},
		-- Tag =		{fg = lvim.color_8},
		-- Label =		{fg = lvim.color_2},
		-- Structure =	{fg = lvim.color_2},
		-- Operator =	{fg = lvim.color_5},
		-- Title =		{fg = lvim.color_2},
		-- Special =	{fg = lvim.fg, style = "bold"},
		-- SpecialChar =			{fg = lvim.fg, style = "bold"},
		-- Type =		{fg = lvim.color_11},
		-- Function =	{fg = lvim.color_3},
		-- String =	{fg = lvim.color_4},
		-- Character =	{fg = lvim.color_5},
		-- Constant =	{fg = lvim.color_7},
		-- Macro =		{fg = lvim.color_7},
		-- Identifier =			{fg = lvim.color_8},
		-- Comment =	{fg = lvim.color_6},
		-- SpecialComment	{fg = lvim.color_6},
		-- Todo =		{fg = lvim.color_6},
		-- Delimiter =	{fg = lvim.color_5},
		-- Ignore =	{fg = lvim.color_12},
		-- Underlined =			{fg = lvim.none, style = "underline"},
	}
	return syntax
end

function one.load_plugin_syntax()
	local plugin_syntax = {
		-- TSAnnotation = {fg = lvim.color_0},
		-- TSAttribute = {fg = lvim.color_1},
		-- TSBoolean = {fg = lvim.color_2},
		-- TSCharacter = {fg = lvim.color_3},
		-- TSConditional = {fg = lvim.color_4},
		-- TSConstant = {fg = lvim.color_5},
		-- TSEmphasis = {fg = lvim.color_3},
		-- TSError = {fg = lvim.color_7},
		-- TSException = {fg = lvim.color_1},
		-- TSField = {fg = lvim.color_9},
		-- TSFloat = {fg = lvim.color_10},
		-- TSFuncBuiltin = {fg = lvim.color_3},
		-- TSFuncMacro = {fg = lvim.color_12},
		-- TSKeywordFunction = {fg = lvim.color_3},
		-- TSLiteral = {fg = lvim.color_10},
		-- TSNamespace = {fg = lvim.color_0},
		-- TSNumber = {fg = lvim.color_1},
		-- TSParameterReference = {fg = lvim.color_2},
		-- TSPunctSpecial = {fg = lvim.color_3},
		-- TSRepeat = {fg = lvim.color_4},
		-- TSString = {fg = lvim.color_5},
		-- TSStringEscape = {fg = lvim.color_6},
		-- TSStringRegex = {fg = lvim.color_7},
		-- TSStrong = {fg = lvim.color_1},
		-- TSStructure = {fg = lvim.color_9},
		-- TSText = {fg = lvim.color_10},
		-- TSTitle = {fg = lvim.color_11},
		-- TSTypeBuiltin = {fg = lvim.color_3},
		-- TSUnderline = {fg = lvim.color_13},
		-- TSURI = {fg = lvim.color_10},
		-- TSInclude = {fg = lvim.color_0},
		-- TSPunctBracket = {fg = lvim.color_2},
		-- TSPunctDelimiter = {fg = lvim.color_2},
		-- TSType = {fg = lvim.color_11},
		-- TSFunction = {fg = lvim.color_9},
		-- TSTagDelimiter = {fg = lvim.color_6},
		-- TSProperty = {fg = lvim.color_3},
		-- TSMethod = {fg = lvim.color_1},
		-- TSParameter = {fg = lvim.color_9},
		-- TSConstructor = {fg = lvim.color_3},
		-- TSVariable = {fg = lvim.color_9},
		-- TSOperator = {fg = lvim.color_3},
		-- TSKeyword = {fg = lvim.color_0},
		-- TSVariableBuiltin = {fg = lvim.color_10},
		-- TSTag = {fg = lvim.color_3},
		-- TSLabel = {fg = lvim.color_1},
		-- GitGutterAdd = {fg = lvim.color_add},
		-- GitGutterChange = {fg = lvim.color_change},
		-- GitGutterDelete = {fg = lvim.color_delete},
		-- GitGutterChangeDelete = {fg = lvim.color_change_delete},
		-- GitSignsAdd = {fg = lvim.color_add},
		-- GitSignsChange = {fg = lvim.color_change},
		-- GitSignsDelete = {fg = lvim.color_delete},
		-- GitSignsAddNr = {fg = lvim.color_add},
		-- GitSignsChangeNr = {fg = lvim.color_change},
		-- GitSignsDeleteNr = {fg = lvim.color_delete},
		-- GitSignsAddLn = {fg = lvim.color_add},
		-- GitSignsChangeLn = {fg = lvim.color_change},
		-- GitSignsDeleteLn = {fg = lvim.color_delete},
		-- SignifySignAdd = {fg = lvim.color_add},
		-- SignifySignChange = {fg = lvim.color_change},
		-- SignifySignDelete = {fg = lvim.color_delete},
		-- LspDiagnosticsSignError = {fg = lvim.color_error},
		-- LspDiagnosticsSignWarning = {fg = lvim.color_warning},
		-- LspDiagnosticsSignInformation = {fg = lvim.color_info},
		-- LspDiagnosticsSignHint = {fg = lvim.color_info},
		-- LspDiagnosticsVirtualTextError = {fg = lvim.color_error},
		-- LspDiagnosticsVirtualTextWarning = {fg = lvim.color_warning},
		-- LspDiagnosticsVirtualTextInformation = {fg = lvim.color_info},
		-- LspDiagnosticsVirtualTextHint = {fg = lvim.color_info},
		-- LspSignatureActiveParameter = {fg = lvim.color_info},
		-- LspDiagnosticsUnderlineError = {
			-- style = "undercurl",
			-- sp = lvim.color_error
		-- },
		-- LspDiagnosticsUnderlineWarning = {
			-- style = "undercurl",
			-- sp = lvim.color_warning
		-- },
		-- LspDiagnosticsUnderlineInformation = {
			-- style = "undercurl",
			-- sp = lvim.color_info
		-- },
		-- LspDiagnosticsUnderlineHint = {
			-- style = "undercurl",
			-- sp = lvim.color_info
		-- },
		-- LvimHelperNormal = {fg = lvim.color_6, bg = lvim.base2},
		-- LvimHelperTitle = {fg = lvim.color_9, bg = lvim.none},
		-- NvimTreeNormal = {bg = lvim.black_background},
		-- NvimTreeFolderName = {fg = lvim.color_4},
		-- NvimTreeOpenedFolderName = {fg = lvim.color_11},
		-- NvimTreeEmptyFolderName = {fg = lvim.color_4},
		-- NvimTreeRootFolder = {fg = lvim.color_4},
		-- NvimTreeSpecialFile = {fg = lvim.fg, bg = lvim.none, style = "NONE"},
		-- NvimTreeFolderIcon = {fg = lvim.color_4},
		-- NvimTreeIndentMarker = {fg = lvim.hl},
		-- NvimTreeSignError = {fg = lvim.color_error},
		-- NvimTreeSignWarning = {fg = lvim.color_warning},
		-- NvimTreeSignInformation = {fg = lvim.color_info},
		-- NvimTreeSignHint = {fg = lvim.color_info},
		-- NvimTreeLspDiagnosticsError = {fg = lvim.color_error},
		-- NvimTreeLspDiagnosticsWarning = {fg = lvim.color_warning},
		-- NvimTreeLspDiagnosticsInformation = {fg = lvim.color_info},
		-- NvimTreeLspDiagnosticsHint = {fg = lvim.color_info},
		-- NvimTreeWindowPicker = {gui = "bold", fg = lvim.bg, bg = lvim.color_9},
		-- TroubleNormal = {bg = lvim.black_background},
		-- TelescopeBorder = {fg = lvim.color_11},
		-- TelescopePromptBorder = {fg = lvim.color_3},
		-- TelescopeMatching = {fg = lvim.color_11},
		-- TelescopeSelection = {fg = lvim.color_3, bg = lvim.bg_highlight},
		-- TelescopeSelectionCaret = {fg = lvim.color_3},
		-- TelescopeMultiSelection = {fg = lvim.color_11},
		-- Floaterm = {fg = lvim.color_9},
		-- FloatermBorder = {fg = lvim.color_1},
	}
	return plugin_syntax
end

local async_load_plugin

async_load_plugin = vim.loop.new_async(vim.schedule_wrap(function()
	local syntax = one.load_plugin_syntax()
	for group, colors in pairs(syntax) do one.highlight(group, colors) end
	async_load_plugin:close()
end))

function one.colorscheme()
	one.transform(one.palette)
	vim.api.nvim_command("hi clear")
	if vim.fn.exists("syntax_on") then vim.api.nvim_command("syntax reset") end
	vim.g.colors_name = "one"
	local syntax = one.load_syntax()
	for group, colors in pairs(syntax) do one.highlight(group, colors) end
	async_load_plugin:send()
end

one.colorscheme()

return one

--[[
print('-- SORTED BY LIGHTNESS --')
table.sort(palette, sort_by_light_dec)
for _, sub in ipairs(palette) do print(sub[2]) end

print('-- SORTED BY SATURATION --')
table.sort(palette, sort_by_sat_dec)
for _, sub in ipairs(palette) do print(sub[2]) end

print('-- SORTED BY REDNESS --')
table.sort(palette, sort_by_red_dec)
for _, sub in ipairs(palette) do print(sub[2]) end

print('-- SORTED BY BLUE --')
table.sort(palette, sort_by_blue_dec)
for _, sub in ipairs(palette) do print(sub[2]) end

print('-- SORTED BY HUE --')
table.sort(palette, sort_by_hue)
for _, sub in ipairs(palette) do print(sub[2]) end
]]
