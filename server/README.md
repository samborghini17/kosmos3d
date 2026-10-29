# Windows receiver

Run `pwsh -File server/start_receiver.ps1` from this checkout. Default storage is
`D:\STORAGE\SAM\KOSMOS3D_UPLOADS`; default port is 8787. This receiver stores files;
it does not run photogrammetry or Gaussian splatting reconstruction.

In Transfers > Configure destination, select **KOSMOS transfer server**. Use the
computer's LAN address (currently `http://192.168.88.13:8787`) and paste the token
from `%LOCALAPPDATA%\KOSMOS3D\receiver-token.txt` into Access token. The token is
created locally and never included in source control. Choose Test connection.
Phone and Windows must have a route to one another. A phone connected directly
to a GoPro must finish importing and leave that network before a LAN upload.
For USB-connected Android development, `adb reverse tcp:8787 tcp:8787` makes
`http://127.0.0.1:8787` reach this receiver. The reverse mapping ends on disconnect.

If Windows Firewall blocks LAN access, allow TCP 8787 only on your trusted private
network. Do not expose this development HTTP server to the Internet. Use a proper
HTTPS reverse proxy, quota controls and a per-user authentication service before
public hosting. Token authentication and SHA-256 verification are mandatory.

Files arrive under `<storage>/<project-id>/<relative-path>`. Originals, project
JSON, sensor logs, LiDAR captures and import receipts can be uploaded together.
Uploads use temporary files followed by atomic replacement after checksum
verification. Retrying skips identical completed files. Partial uploads restart
from the beginning of that file, not the interrupted byte offset.

Stop the foreground launcher with Ctrl+C. No startup service is installed.
