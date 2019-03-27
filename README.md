# BonjourMenu
**BonjourMenu** adds a system status menu that lists local network Bonjour services.

## Background
Safari previously included Bonjour webpages and printers in the bookmarks menu, however this feature was removed in Safari 11. **BonjourMenu** restores this functionality and moves the menu to the system menu bar so it is always available.

## Screenshot
<img width="255" alt="screen shot" src="https://user-images.githubusercontent.com/57339/34313022-0f5874a4-e71d-11e7-9282-695586523e49.png">

## Features
In addition to restoring access to Bonjour webpages and printers, **BonjourMenu** also displays other common services, facilitating access to Mac/Windows file shares, Plex media servers, Raspberry Pis (advertising with Avahi), and IoT devices.

| Type | Service | Launch URL | Application | 
| --- | --- | --- | --- |
| _http._tcp. | HTTP | `http://<u>:<p>@server:port/<path>` | Safari |
| _afpovertcp._tcp. | Apple File Protocol | `afp://<u>:<p>@server:port/<path>` | Finder |
| _smb._tcp. | Samba | `smb://<u>:<p>@server:port/<path>` | Finder |
| _ssh._tcp. | SSH | `ssh://<u>:<p>@server:port/<path>` | Terminal |
| _rfb._tcp. | VNC | `vnc://<u>:<p>@server:port/<path>` | Screen&nbsp;Sharing |
| _plexmediasvr._tcp. | Plex | `http://<u>:<p>@server:port/<path>` | Safari |
| _ipp._tcp. | Internet Printing Protocol | `ipp://<u>:<p>@server:port/<path>` | Preferences |

Note: the `<u>`, `<p>`, and `<path>` variables are set via the Bonjour TXT record [as specified in the RFC](http://www.dns-sd.org/ServiceTypes.html)

## Similar
[Bonjour Browser](http://tildesoft.com) by Lily Ballard
