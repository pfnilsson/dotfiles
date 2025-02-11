local ok, secrets = pcall(require, "fredrik.secrets")
if not ok then
    secrets = require("fredrik.secrets_fallback")
end

return secrets
