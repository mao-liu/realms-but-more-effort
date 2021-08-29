So much effort

# Start server

- Change ASG to 1/1/1
- Server auto-saves to s3 every 10 minutes

# Stop server

- From in-game as operator, run `/stop`
- OR, from SSM run command on EC2, `cd /var/realms/server && make stop`
- Game will save and upload world to s3
- Game will reset ASG to 0/0/0
