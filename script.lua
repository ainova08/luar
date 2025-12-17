-- ===== Base64 decode =====
local function base64_decode(data)
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  data = tostring(data or ""):gsub('[^'..b..'=]', '')
  local decoded = (data:gsub('.', function(x)
    if x == '=' then return '' end
    local f = (b:find(x, 1, true) or 1) - 1
    local r = ''
    for i = 6, 1, -1 do
      r = r .. (f % 2^i - f % 2^(i-1) > 0 and '1' or '0')
    end
    return r
  end):gsub('%d%d%d%d%d%d%d%d', function(x)
    local c = 0
    for i = 1, 8 do
      c = c + (x:sub(i,i) == '1' and 2^(8-i) or 0)
    end
    return string.char(c)
  end))
  return decoded or ""
end

-- ===== URL encode =====
local function url_encode(str)
  local encoded = (tostring(str or ""):gsub('\n','\r\n'):gsub('([^%w%-_%.~])', function(c)
    return string.format('%%%02X', string.byte(c))
  end))
  return encoded
end

-- ===== Input =====
local input = gg.prompt({"กรอกคีย์เพื่อใช้งานสคริปต์"}, nil, {"text"})
local key = tostring(input and input[1] or "")
if key == "" then
  gg.alert("❌ กรุณากรอกคีย์ก่อนใช้งาน")
  os.exit()
else

end

-- ===== Encoded URLs =====
local encodedGenerate = "aHR0cHM6Ly9sdWEta2V5LWFwaS5vbnJlbmRlci5jb20vZ2VuZXJhdGVUb2tlbjZzP2tleT0="
local encodedCore     = "aHR0cHM6Ly9sdWEta2V5LWFwaS5vbnJlbmRlci5jb20vZ2V0Q29yZUJ5VG9rZW4/dG9rZW49"

-- ===== Decode URLs =====
local generateBase = base64_decode(encodedGenerate)
local coreBase     = base64_decode(encodedCore)

if generateBase == "" or coreBase == "" then
  gg.alert("❌ Base64 decode ไม่สำเร็จ")
  os.exit()
end


-- ===== ตัด 2 ตัวท้ายออกก่อนต่อคีย์ =====
local trimmedBase = string.sub(generateBase, 1, -3)
local generateUrl = trimmedBase .. url_encode(key)


-- ===== Request token =====
local genRes = gg.makeRequest(generateUrl)
local token = genRes and genRes.content or ""

if token == "" then
  gg.alert("❌ ขอ token ไม่สำเร็จ: เซิร์ฟเวอร์ไม่ตอบกลับหรือส่งค่าว่าง")
  os.exit()
else

end

if token == "invalid_key" or token == "expired_key" or token == "missing_key" then
  gg.alert("❌ คีย์ไม่ถูกต้องหรือหมดอายุ ")
  os.exit()
end

-- ===== Request Core.lua =====
local coreUrl = coreBase .. url_encode(token)


local coreRes = gg.makeRequest(coreUrl)

if coreRes and coreRes.code == 200 and coreRes.content then

  local ok, err = pcall(function() load(coreRes.content)() end)
  if ok then

  else
    gg.alert("❌ รัน Core.lua ล้มเหลว: " .. tostring(err))
    os.exit()
  end
else
  gg.alert("❌ โหลด Core.lua ไม่สำเร็จ ")
  os.exit()
end
