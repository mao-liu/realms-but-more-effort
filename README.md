# realms-but-more-effort
When you could just get Minecraft Realms, but you're a cloud engineer so you put in a lot of effort instead.

## Connecting

### Minecraft

Point your Minecraft client to `realms.aws.ab-initio.me`.

### API

Use these APIs to start/stop the server
```
GET https://api.realms.aws.ab-initio.me/realms/info
GET https://api.realms.aws.ab-initio.me/realms/debug
POST https://api.realms.aws.ab-initio.me/realms/start
POST https://api.realms.aws.ab-initio.me/realms/stop

Authorization: Bearer {key}
```
