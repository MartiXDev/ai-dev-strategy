# Approved Verbs for PowerShell Commands

Source: https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands

PowerShell uses a verb-noun pair for the names of cmdlets and for their derived .NET classes. The verb part of the name identifies the action that the cmdlet performs. The noun part of the name identifies the entity on which the action is performed.

**Use `Get-Verb` cmdlet to see the complete list of approved verbs.**

## Verb Naming Recommendations

- Use one of the predefined verb names provided by PowerShell
- Use the verb to describe the general scope of the action, and use parameters to further refine the action of the cmdlet
- Don't use a synonym of an approved verb (e.g., always use `Remove`, never `Delete` or `Eliminate`)
- Use only the form of each verb that's listed (e.g., use `Get`, not `Getting` or `Gets`)
- Don't use reserved verbs: `ForEach`, `Ping` (use `Test`), `Sort`, `Tee`, `Where`

## Similar Verbs - Important Distinctions

- **New vs. Add**: `New` creates a new resource; `Add` adds to an existing container
- **New vs. Set**: `New` creates; `Set` modifies existing resource (optionally creating it)
- **Find vs. Search**: `Find` looks for an object; `Search` creates a reference to a resource
- **Get vs. Read**: `Get` obtains info about a resource; `Read` opens and extracts info within
- **Invoke vs. Start**: `Invoke` performs synchronous operations; `Start` begins asynchronous operations

## Common Verbs

### Data Access
- **Get** (g) - Retrieve a resource (paired with Set)
- **Set** (s) - Replace data or create resource with data (paired with Get)
- **Read** (rd) - Acquire information from a source (paired with Write)
- **Write** (wr) - Add information to a target (paired with Read)

### Data Modification
- **Add** (a) - Add resource to container (paired with Remove)
- **Remove** (r) - Delete resource from container (paired with Add)
- **Clear** (cl) - Remove all resources from container but don't delete container
- **Copy** (cp) - Copy resource to another name/container
- **Move** (m) - Move resource from one location to another

### Creation and Deletion
- **New** (n) - Create a resource
- **Remove** (r) - Delete a resource

### Resource State
- **Open** (op) - Make resource accessible/available (paired with Close)
- **Close** (cs) - Make resource inaccessible/unavailable (paired with Open)
- **Lock** (lk) - Secure a resource (paired with Unlock)
- **Unlock** (uk) - Release a locked resource (paired with Lock)
- **Hide** (h) - Make resource undetectable (paired with Show)
- **Show** (sh) - Make resource visible (paired with Hide)

### Validation and Testing
- **Test** (t) - Verify operation or consistency of a resource
- **Confirm** (cn) - Acknowledge, verify, or validate state
- **Measure** (ms) - Identify consumed resources or retrieve statistics

### Data Operations
- **Compare** (cr) - Evaluate data from one resource against another
- **Convert** (cv) - Change data representation (bidirectional/multiple types)
- **ConvertFrom** (cf) - Convert one primary input type to one or more output types
- **ConvertTo** (ct) - Convert from one or more input types to a primary output type
- **Join** (j) - Combine resources into one (paired with Split)
- **Split** (sl) - Separate parts of a resource (paired with Join)
- **Group** (gp) - Arrange or associate resources
- **Select** (sc) - Locate a resource in a container

### Data Persistence
- **Export** (ep) - Encapsulate input into persistent store/interchange format (paired with Import)
- **Import** (ip) - Create resource from persistent store/interchange format (paired with Export)
- **Backup** (ba) - Store data by replicating it
- **Restore** (rr) - Set resource to predefined state
- **Save** (sv) - Preserve data to avoid loss
- **Sync** (sy) - Ensure two or more resources are in the same state

### Navigation
- **Enter** (et) - Move into a resource (paired with Exit)
- **Exit** (ex) - Set context to most recently used (paired with Enter)
- **Push** (pu) - Add item to top of stack
- **Pop** (pop) - Remove item from top of stack

### Communication Verbs
- **Connect** (cc) - Create link between source and destination (paired with Disconnect)
- **Disconnect** (dc) - Break link between source and destination (paired with Connect)
- **Send** (sd) - Deliver information to a destination (paired with Receive)
- **Receive** (rc) - Accept information from a source (paired with Send)

### Lifecycle Verbs
- **Install** (is) - Place a resource in a location and optionally initialize it (paired with Uninstall)
- **Uninstall** (us) - Remove a resource from an indicated location (paired with Install)
- **Deploy** (dp) - Deploy an application/solution/package
- **Build** (bd) - Create an artifact from input files
- **Invoke** (i) - Perform a synchronous operation
- **Start** (sa) - Begin an asynchronous operation (paired with Stop)
- **Stop** (sp) - Discontinue an activity (paired with Start)
- **Enable** (en) - Make a resource available/active (paired with Disable)
- **Disable** (d) - Make a resource unavailable/inactive (paired with Enable)

### Diagnostic Verbs
- **Debug** (db) - Examine a resource to diagnose problems
- **Trace** (tr) - Track activities of a resource
- **Resolve** (rv) - Map shorthand representation to complete representation
- **Repair** (rp) - Restore a resource to usable condition

### Formatting and Output
- **Format** (f) - Arrange objects in a specified form or layout
- **Out** (o) - Send data out of the environment

### Advanced Operations
- **Update** (ud) - Bring a resource up-to-date
- **Optimize** (om) - Increase effectiveness of a resource
- **Initialize** (in) - Prepare a resource and set to default state
- **Compress** (cm) - Compact resource data (paired with Expand)
- **Expand** (en) - Restore compressed data to original state (paired with Compress)
- **Undo** (un) - Set resource to previous state
- **Redo** (re) - Reset resource to state that was undone

## Alias Prefixes

Each approved verb has a corresponding alias prefix for use in command aliases. Examples:
- Import → ip (e.g., `Import-Module` → `ipmo`)
- Get → g (e.g., `Get-Command` → `gcm`)
- Set → s (e.g., `Set-Location` → `sl`)
