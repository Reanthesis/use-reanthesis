# Authentication

Adding `https://reanthesis.com/mcp` as a connector ends on the Reanthesis
authorize screen: the user signs in if needed, reads exactly what the
connection can and cannot do, and taps **Allow**. No password ever passes
through the AI, the client, or an MCP tool.

## The OAuth flow

MCP clients discover the OAuth surface from the server URL, with no
per-client configuration:

1. An unauthenticated request to `/mcp` returns `401` with a
   `WWW-Authenticate` header pointing at the protected-resource metadata
   (RFC 9728), which names the authorization server.
2. The authorization-server metadata (RFC 8414) advertises dynamic client
   registration (RFC 7591) and the authorization-code grant.
3. The client registers as a public client (`token_endpoint_auth_method:
   none`), sends the user to `/oauth/authorize` with PKCE (S256 only), and
   the browser lands on the Reanthesis authorize screen.
4. **Allow** issues a single-use authorization code; **Deny** returns
   `access_denied`. The client exchanges the code at `/oauth/token` and
   receives a connector token.

Redirect URIs must be HTTPS or loopback HTTP; loopback redirects may vary
their port between registration and authorization (RFC 8252 §7.3), which is
how editor and CLI clients bind an ephemeral port. Refresh tokens are not
issued yet; an expired token means one more Allow tap.

## The connector token

Connector tokens are opaque `rc_`-prefixed secrets, stored hashed on the
server, valid for 180 days. A password reset revokes every connector token on
the account.

The token is scoped server-side, deny by default:

- It can: create and edit decks and cards, wake and rest cards, search tags,
  read study stats, and upload card images.
- It cannot: touch account settings, billing, or membership; delete the
  account; run exports or imports; or submit reviews. Reviewing is the point
  of studying — it stays with the human.

A revoked or expired token makes every tool return one clear instruction:
reconnect at reanthesis.com.

## Privacy boundaries

- The user's own AI reads the user's material and performs the inference.
- Reanthesis stores cards and study state and schedules with FSRS; it does
  not provide or pay for inference, and adds no third-party analytics to this
  integration.
- Account creation is never an MCP operation. Connectors attach to accounts;
  they do not make them.
