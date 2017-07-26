local aws_auth = require "resty/aws_auth"
local aws_creds = require "aws_creds"
local creds = aws_creds.get_iam_credentials('iam_creds')

-- Read in the request body - we need it later on
ngx.req.read_body()
local request_body_file = ngx.req.get_body_file()
local request_body
-- The request may be in a file or memory depending on size and so we need to
-- deal with both options
if request_body_file then
  local f = io.open(request_body_file, "r")
  request_body = f:read("*all")
  f:close()
else
  request_body = ngx.req.get_body_data()
end

local cont_type = ngx.req.get_headers()["Content-Type"]
if cont_type == nil then
  cont_type = ""
end

local config = {
  aws_host       = "elasticsearch",
  aws_key        = creds['aws_access_key_id'],
  aws_secret     = creds['aws_secret_access_key'],
  aws_region     = "{{region}}",
  aws_service    = "es",
  content_type   = cont_type,
  request_method = ngx.req.get_method(),
  request_path   = ngx.var.uri,
  request_body   = request_body,
  request_args   = ngx.req.get_uri_args()
}
local aws = aws_auth:new(config)


ngx.req.set_header('X-Amz-Date', aws:get_date_header())
ngx.req.set_header('Authorization', aws:get_authorization_header())
if creds.aws_security_token then
  -- If we're using temporary IAM credentials, then we need to include the
  -- security token as a header
  ngx.req.set_header('X-Amz-Security-Token', creds.aws_security_token)
end