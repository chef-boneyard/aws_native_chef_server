local cjson = require 'cjson'

local _M = {}

function _M.parse_isotime(timestr)
  local m = ngx.re.match(timestr,
    '(\\d{4})-(\\d{2})-(\\d{2})T(\\d{2}):(\\d{2}):(\\d{2})Z')
  if m then
    local tt = {
      year = m[1],
      month = m[2],
      day = m[3],
      hour = m[4],
      min = m[5],
      sec = m[6]
    }
    local timestamp = os.time(tt)
    -- The timestamp is in utc, but we calculated it as if it was local time
    -- so correct for it here.
    local now = ngx.time()
    local utcoffset = os.difftime(now, os.time(os.date("!*t", now)))
    return timestamp + utcoffset
  end
  return nil
end

function _M.get_iam_credentials(shared_dict)
  local shd = ngx.shared[shared_dict]
  if shd:get("aws_access_key_id") == nil then
    -- There's no cached value
    local creds = _M.get_iam_credentials_uncached()
    local grace_period = 900 -- seconds
    local expiration = _M.parse_isotime(creds['expiration']) - ngx.time() - grace_period
    shd:set("aws_access_key_id", creds["aws_access_key_id"], expiration)
    shd:set("aws_secret_access_key", creds["aws_secret_access_key"], expiration)
    shd:set("aws_security_token", creds["aws_security_token"], expiration)
    ngx.log(ngx.DEBUG, "Cached new IAM credentials. TTL: " ..
      expiration .. "s (" .. creds['expiration'] .. " with " .. grace_period ..
      "s grace period) ")
    return creds
  else
    return {
      aws_access_key_id = shd:get("aws_access_key_id"),
      aws_secret_access_key = shd:get("aws_secret_access_key"),
      aws_security_token = shd:get("aws_security_token")
    }
  end
end

function _M.get_iam_credentials_uncached()
  -- You need /_awsapi proxied to http://169.254.169.254 for this to work
  local metadata_path = '/_awsapi/latest/meta-data/iam/security-credentials/'

  local res = ngx.location.capture(metadata_path)
  if not res then
    return
  end
  ngx.log(ngx.DEBUG, "Detected IAM profile: " .. res.body)
  res = ngx.location.capture(metadata_path .. res.body)
  if not res then
    return
  end

  local creds = cjson.decode(res.body)
  return {
    aws_access_key_id = creds['AccessKeyId'],
    aws_secret_access_key = creds['SecretAccessKey'],
    aws_security_token = creds['Token'],
    expiration = creds['Expiration']
  }
end

return _M
