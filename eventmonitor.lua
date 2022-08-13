while true do
  local e = {os.pullEvent()}

  if e[1] ~= "timer" and e[1] then
    term.setTextColor(colors.white)
    print(unpack(e))
  end
end