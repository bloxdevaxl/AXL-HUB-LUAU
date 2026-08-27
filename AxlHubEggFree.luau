-- الانتظار لمدة ثانيتين قبل تشغيل السكربت الأساسي الأول
task.wait(2)
local success1, err1 = pcall(function()
    loadstring(game:HttpGet("https://pastebin.com/raw/kyLPbnLA"))()
end)
if not success1 then
    warn("فشل تشغيل السكربت الأول: " .. tostring(err1))
end

-- الانتظار لمدة ثانية إضافية قبل تشغيل السكربت الثاني
task.wait(1)
local success2, err2 = pcall(function()
    loadstring(game:HttpGet("https://pastebin.com/raw/YgDaCgcD"))()
end)
if not success2 then
    warn("فشل تشغيل السكربت الثاني: " .. tostring(err2))
end

-- تشغيل السكربت الثالث مباشرة
local success3, err3 = pcall(function()
    loadstring(game:HttpGet("https://pastebin.com/raw/CQyhbj38"))()
end)
if not success3 then
    warn("فشل تشغيل السكربت الثالث: " .. tostring(err3))
end
