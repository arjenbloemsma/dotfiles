-- Personal keybinding overrides, loaded after Omarchy's defaults.
-- See current bindings: omarchy menu keybindings --print

-- Vim-style window focus on SUPER + H/J/K/L (arrow keys still work).
-- The displaced defaults move to SUPER + SHIFT + same letter.
o.bind("SUPER + H", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.rebind("SUPER + J", "Focus on below window", hl.dsp.focus({ direction = "d" }))
o.rebind("SUPER + K", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.rebind("SUPER + L", "Focus on right window", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + SHIFT + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + SHIFT + K", "Keybindings", "omarchy-menu-keybindings")
o.bind("SUPER + SHIFT + L", "Cycle workspace layout", "omarchy-hyprland-workspace-layout-toggle")
