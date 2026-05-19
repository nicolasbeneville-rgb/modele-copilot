---
name: vsg-integration
description: "Standard patterns for integrating VeoliaSecureGPT (VSG) LLM API in Google Apps Script projects. Use when adding AI/LLM features that call the Veolia corporate API."
---

# VSG Integration — Standard Patterns

## Use When
- Adding LLM/AI features to a GAS project
- Configuring OAuth2 token flow for VSG
- Choosing the right VSG product (Common vs Flex)
- Implementing token caching, retry, or sanitization

## VSG Products

| Product | Auth | Quota | Endpoint base |
|---------|------|-------|---------------|
| VSG Common | OAuth2 Client Credentials | 2000 calls/month/user | `https://api.veolia.com/llm/veoliasecuregpt/v1` |
| VSG Flex | API Key or OAuth2 | Unlimited (per token) | `https://api.veolia.com/llm/flex/veoliasecuregpt/v1` |

Default: use **VSG Common** unless quota is insufficient.

## Endpoints

- Token: `POST https://api.veolia.com/security/v2/oauth/token`
- Chat: `POST {endpoint_base}/chat/completions` (OpenAI-compatible format)

## Available Models (2026)
- `anthropic.claude-v4.5` ← recommended default
- `anthropic.claude-v3.5-sonnet`
- `gpt-4o-mini`, `gpt-4o`, `gpt-4.1-mini`, `gpt-4.1`

## Auth Flow (OAuth2 Client Credentials)
```
POST https://api.veolia.com/security/v2/oauth/token
Header: Authorization: Basic base64(client_id:client_secret)
Body: grant_type=client_credentials
Content-Type: application/x-www-form-urlencoded
→ Response: { "access_token": "...", "expires_in": 3600 }
```

## Required Script Properties
| Key | Purpose |
|-----|---------|
| VSG_CLIENT_ID | OAuth2 client ID (from Apigee portal) |
| VSG_CLIENT_SECRET | OAuth2 client secret |
| VSG_ENDPOINT | Base URL without /chat/completions |
| VSG_MODEL | LLM model identifier |
| VSG_TEMPERATURE | 0–1 (default 0.3) |

**NEVER** hardcode secrets in source code.

## Implementation Checklist

### 1. Token Caching (mandatory)
- Store token in `UserProperties` (not CacheService — survives quota resets)
- TTL: **55 minutes** (token expires at 60 min)
- Keys: `VSG_CACHED_TOKEN`, `VSG_TOKEN_EXPIRY` (epoch ms)

### 2. Retry on 401/403 (mandatory)
- If LLM call returns 401 or 403 → invalidate cached token → get fresh token → retry once
- Never retry more than once (avoid infinite loops)

### 3. Surrogate Sanitization (mandatory for Claude/Bedrock)
- Remove isolated Unicode surrogates (U+D800–U+DFFF) before sending to LLM
- Pattern: `text.replace(/[\uD800-\uDFFF]/g, '')`
- Reason: Bedrock/Claude reject payloads with unpaired surrogates

### 4. Request Payload (OpenAI-compatible)
```json
{
  "model": "anthropic.claude-v4.5",
  "messages": [
    {"role": "system", "content": "..."},
    {"role": "user", "content": "..."}
  ],
  "temperature": 0.3,
  "max_tokens": 4096,
  "user": "prenom.nom@veolia.com"
}
```
- `user` field: populate from `Session.getActiveUser().getEmail()` (required for Common, optional for Flex)

### 5. Response Parsing
```javascript
var data = JSON.parse(resp.getContentText());
var content = data.choices[0].message.content;
```

### 6. Error Handling
- `muteHttpExceptions: true` on all UrlFetchApp calls
- Check `getResponseCode()` before parsing
- Truncate error messages in user-facing responses (max 300 chars)

## Reference Implementation (GAS)
```javascript
function getVSGToken_(forceRefresh) {
  var userProps = PropertiesService.getUserProperties();
  if (!forceRefresh) {
    var cached = userProps.getProperty('VSG_CACHED_TOKEN');
    var expiry = parseInt(userProps.getProperty('VSG_TOKEN_EXPIRY') || '0');
    if (cached && Date.now() < expiry) return cached;
  }
  var props = PropertiesService.getScriptProperties();
  var cid = props.getProperty('VSG_CLIENT_ID');
  var cs = props.getProperty('VSG_CLIENT_SECRET');
  if (!cid || !cs) throw new Error('VSG credentials missing');
  var r = UrlFetchApp.fetch('https://api.veolia.com/security/v2/oauth/token', {
    method: 'post',
    headers: { 'Authorization': 'Basic ' + Utilities.base64Encode(cid + ':' + cs) },
    payload: 'grant_type=client_credentials',
    contentType: 'application/x-www-form-urlencoded',
    muteHttpExceptions: true
  });
  if (r.getResponseCode() !== 200) throw new Error('OAuth failed: ' + r.getContentText().substring(0, 200));
  var token = JSON.parse(r.getContentText()).access_token;
  userProps.setProperty('VSG_CACHED_TOKEN', token);
  userProps.setProperty('VSG_TOKEN_EXPIRY', String(Date.now() + 55 * 60 * 1000));
  return token;
}

function callVSG_(messages, options) {
  var props = PropertiesService.getScriptProperties();
  var endpoint = props.getProperty('VSG_ENDPOINT');
  var model = (options && options.model) || props.getProperty('VSG_MODEL') || 'anthropic.claude-v4.5';
  var temp = (options && options.temperature != null) ? options.temperature : 0.3;
  var clean = messages.map(function(m) {
    return { role: m.role, content: (m.content || '').replace(/[\uD800-\uDFFF]/g, '') };
  });
  var body = JSON.stringify({ model: model, messages: clean, temperature: temp, max_tokens: 4096, user: Session.getActiveUser().getEmail() });
  var token = getVSGToken_(false);
  var r = UrlFetchApp.fetch(endpoint + '/chat/completions', {
    method: 'post', headers: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
    payload: body, muteHttpExceptions: true
  });
  if (r.getResponseCode() === 401 || r.getResponseCode() === 403) {
    PropertiesService.getUserProperties().deleteProperty('VSG_CACHED_TOKEN');
    token = getVSGToken_(true);
    r = UrlFetchApp.fetch(endpoint + '/chat/completions', {
      method: 'post', headers: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
      payload: body, muteHttpExceptions: true
    });
  }
  if (r.getResponseCode() !== 200) throw new Error('VSG error HTTP ' + r.getResponseCode());
  return JSON.parse(r.getContentText());
}
```

## Legacy Note
Some older Veolia projects use the `/v1/answer` endpoint with a proprietary payload format (`{ useremail, model, temperature, top_p, history }`). New projects MUST use the OpenAI-compatible `/chat/completions` format above.

## Apigee Gateway Context

VSG APIs are exposed through **Apigee X** — Veolia's centralized API Management platform.

### What this means for integration:
- All `https://api.veolia.com/*` traffic goes through Apigee proxy
- **Spike Arrest**: Apigee enforces rate limits (default 1000 req/day) — a 429 can come from Apigee before reaching the LLM backend
- **Quota**: Enforced at Apigee Product level — returns HTTP 429 when exceeded
- **Security**: 54 mandatory API security rules, TLS 1.2 only, Cloud Armor protection
- **Logging**: All calls logged in BigQuery (consumer app, request, response code)
- **Scopes**: OAuth2 scopes can restrict access per resource (not currently used for VSG Common)

### HTTP error codes from Apigee:
| Code | Source | Meaning | Action |
|------|--------|---------|--------|
| 401 | Apigee/Backend | Token invalid/expired | Refresh token + retry |
| 403 | Apigee | Scope insufficient or app not authorized | Check subscription |
| 429 | Apigee | Quota or Spike Arrest exceeded | Back off, notify user |
| 5xx | Backend | LLM service error | Retry once, then fail gracefully |

### Best practice: handle 429 gracefully
```javascript
if (code === 429) {
  throw new Error('Quota API dépassé. Réessayez plus tard ou contactez l\'admin.');
}
```

### MCP Server (future)
APIs published on Apigee can be exposed as MCP tools in the VSG assistant. This allows natural language API consumption. Prerequisites: APIs published on Apigee + subscription to Apigee product(s).

### Support & Contact
- API Team: `fr.ist.engineeringapi.all.groups@veolia.com`
- ServiceNow portal for requests
- Knowledge Base: Veolia API & Apigee website
