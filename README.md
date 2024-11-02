Hey guys, hope you will enjoy my checksummer (nice brand name btw).

**Core Features:**
 - SHA256 & MD5 sums. 
 - Ability to add any files to the input. Folders will be traversed recursively. 
 - XPC service to perform calculation.
 - Relative path deducing for resulting checksum file.
 - Validation logic.

**UI Features:**
- Main window with input files panel.
- Ability to add files using `NSOpenPanel`, by buttons or by hotkey cmd+O, or by dragging them inside the list.
- Ability to load checksum files and validate checksums of input files against them.
- Dynamic progress indicator with the ability to cancel the operation using the button or Esc key. 
- Ability to save checksum file.
- Ability to view checksum files in a separate window in a table.
- Drag and drop support for checksum file and for input files.

**Architecture Notes**
- App uses MVVM foundation to bind UI with the model.
- Main app contains XPC service. Both of them are dependant on `ChecksumKit` framework to reuse model objects when needed. 
	- Better idea is to create very thin "Model" framework and do not share real "calculation" code between XPC and app. But it was too much for this prototype.
- There are tests on vital core parts, such as hashing correctness and file path resolving.
- For each request, app creates separate `NSXPCConnection` and assigns "Listener" object as proxy to receive progress updates.
	- There is some problem in NSXPC code, and right now listeners are retained indefenitely. I have no idea why and I have no time to fix it (
	- Probably maintaining one single `NSXPCConnection` with task tokens would be better, but it is what it is.

**Notes**
- Thank you for this excellent task. Had a lot of fun with it. 
- I really tried to wipe all the traces of my personality from the project, but maybe you will encounter some breadcrumbs. Please ignore them.
