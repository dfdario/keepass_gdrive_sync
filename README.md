# keepass_gdrive_sync
Synchronize local keepass database file with google drive personal area

<H2>Before use</H2>
<b>RCLONE</b> must be run and configured to be anable exchange files from Local to Google Drive and viceversa</b><br><br>
To configure I have flollowed the following steps:<br>

<H2>Google Drive</H2>
Paths are specified as drive:path<br>
Drive paths may be as deep as required, e.g. <i>drive:directory/subdirectory</i>.

<H2>Configuration</H2>
The initial setup for drive involves getting a token from Google drive which you need to do in your browser. rclone config walks you through it.<br>
Here is an example of how to make a remote called remote. First run:
<b>rclone config</b><br>
This will guide you through an interactive setup process:<br>
No remotes found, make a new one?<br>
n) New remote<br>
r) Rename remote<br>
c) Copy remote<br>
s) Set configuration password<br>
q) Quit config<br>
n/r/c/s/q> <b>n</b><br>
name> <b>remote</b><br><br>
Type of storage to configure.<br>
Choose a number from below, or type in your own value<br>
[snip]<br>
XX / Google Drive -->> <b>19</b><br>
   \ "drive"<br>
[snip]<br>
Storage> <b>drive</b><br><br>
Google Application Client Id - leave blank normally.<br>
client_id><br>
Google Application Client Secret - leave blank normally.<br>
client_secret><br>
Scope that rclone should use when requesting access from drive.<br>
Choose a number from below, or type in your own value<br>
 1 / Full access all files, excluding Application Data Folder.<br>
   \ "drive"<br>
 2 / Read-only access to file metadata and file contents.<br>
   \ "drive.readonly"<br>
   / Access to files created by rclone only.<br>
 3 | These are visible in the drive website.<br>
   | File authorization is revoked when the user deauthorizes the app.<br>
   \ "drive.file"<br>
   / Allows read and write access to the Application Data folder.<br>
 4 | This is not visible in the drive website.<br>
   \ "drive.appfolder"<br>
   / Allows read-only access to file metadata but<br>
 5 | does not allow any access to read or download file content.<br>
   \ "drive.metadata.readonly"<br>
scope> <b>1</b><br>

<H2>Service Account</h2>
Credentials JSON file path - needed only if you want use SA instead of interactive login.<br>
service_account_file> ... leave  blank normally.<br><br>

Edit advanced config?<br>
y) Yes<br>
n) No (default)<br>
y/n> <b>n</b><br>

<h2>Remote config</h2>
Use web browser to automatically authenticate rclone with remote?<br>
 * Say Y if the machine running rclone has a web browser you can use<br>
 * Say N if running rclone on a (remote) machine without web browser access<br>
If not sure try Y. If Y failed, try N.<br>
y) Yes<br>
n) No<br>
y/n> <b>y</b><br><br>
If your browser doesn't open automatically go to the following link:<br>http://127.0.0.1:53682/auth<br>
Log in and authorize rclone for access
Waiting for code...<br>
Got code<br>
Configure this as a Shared Drive (Team Drive)?<br>
y) Yes<br>
n) No<br>
y/n> <b>n</b><br><br>
Configuration complete.<br>
Options:<br>
type: drive<br>
- client_id:<br>
- client_secret:<br>
- scope: drive<br>
- root_folder_id:<br>
- service_account_file:<br>
- token: {"access_token":"XXX",<br>"token_type":"Bearer","refresh_token":"XXX",<br>"expiry":"2014-03-16T13:57:58.955387075Z"}<br>
Keep this "remote" remote?<br>
y) Yes this is OK<br>
e) Edit this remote<br>
d) Delete this remote<br>
y/e/d> <b>y</b><br>
