# Perltainer

A bunch of scripts using portainer's API to do stuff. 

## Usage

```
./{name_of_script}.pl {portainer_url} {portainer_username} {portainer_password} 
```

monitor_env checks for environments status, monitor_container checks for contianers status.

## Example 

```
> ./monitor_container.pl https://portainer.ip:9443 admin 'V3ryStr0ngP4ssword!'

 --- Monitoring started (Fri Apr 12 04:41:45 2024) --- 
 ✅ /test-web-1 is running on host local 
 ✅ /portainer_edge_agent is running on host local 
 ✅ /autotest is running on host local 
 ✅ /anotherContainer is running on host laptopedge 
 ✅ /testPerlMonitoring is running on host laptopedge 
 ✅ /portainer_edge_agent is running on host laptopedge 

 --- Next iteration (Fri Apr 12 04:42:25 2024) --- 
 ⚠️  /test-web-1 is not running on host local. State : exited
 ✅ /portainer_edge_agent is running on host local 
 ✅ /autotest is running on host local 
 ✅ /anotherContainer is running on host laptopedge 
 ⚠️  /testPerlMonitoring is not running on host laptopedge. State : exited
 ✅ /portainer_edge_agent is running on host laptopedge 
```
