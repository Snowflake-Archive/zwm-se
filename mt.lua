while true do
  local e, m, x, y = os.pullEvent("mouse_click") 

  if e == "mouse_click" then
    term.setCursorPos(x, y)
    if m == 1 then
      term.setBackgroundColor(colors.red)
      term.setTextColor(colors.white)
      term.write("X")
    elseif m == 2 then
      term.setBackgroundColor(colors.blue)
      term.setTextColor(colors.white)
      term.write("X")
    elseif m == 3 then
      term.setBackgroundColor(colors.green)
      term.setTextColor(colors.white)
      term.write("X")
    end
  end
end