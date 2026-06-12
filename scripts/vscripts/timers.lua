--==========================================================================================================================
-- GLOBAL LIBRARY
--==========================================================================================================================
-- The timers library. Handles global timers and provides an interface for custom game modes to create them.
--
-- The main timer function is Timers:CreateTimer( fDelay, function() end )
-- Timers:CreateTimer is also used for repeating timers.
--
-- If the function returns a number, it'll be treated as a repeat delay.
-- Returning -1 will cause the timer to not repeat.
-- Returning anything else will cause the timer to repeat with the same delay.
--==========================================================================================================================

if Timers == nil then
	_G.Timers = {}
end

-- Create a global timer.
function Timers:CreateTimer( fDelay, fn, sName )
	return _G.Timers.CreateTimer( fDelay, fn, sName )
end

-- Remove a global timer.
function Timers:RemoveTimer( oTimer )
	_G.Timers.RemoveTimer( oTimer )
end