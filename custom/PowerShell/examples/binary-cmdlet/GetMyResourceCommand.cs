using System;
using System.Management.Automation;

namespace MyCompany.PowerShell
{
    /// <summary>
    /// Get-MyResource cmdlet implementation.
    /// Demonstrates binary cmdlet development in C# for PowerShell 7+.
    /// </summary>
    [Cmdlet(VerbsCommon.Get, "MyResource",
        DefaultParameterSetName = "ByName",
        SupportsShouldProcess = true,
        ConfirmImpact = ConfirmImpact.Low)]
    [OutputType(typeof(MyResource))]
    public class GetMyResourceCommand : Cmdlet
    {
        #region Parameters

        [Parameter(
            Position = 0,
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "ByName",
            HelpMessage = "Specifies one or more resource names")]
        [ValidateNotNullOrEmpty()]
        [Alias("Name", "ResourceName")]
        public string[] Identity { get; set; }

        [Parameter(
            Mandatory = true,
            ParameterSetName = "ById",
            HelpMessage = "Specifies resource by ID")]
        [ValidateRange(1, 9999)]
        public int Id { get; set; }

        [Parameter(HelpMessage = "Include detailed information")]
        public SwitchParameter Detailed { get; set; }

        #endregion

        #region Processing Methods

        protected override void BeginProcessing()
        {
            WriteVerbose($"Parameter set: {ParameterSetName}");
            WriteDebug($"Detailed: {Detailed.IsPresent}");
        }

        protected override void ProcessRecord()
        {
            try
            {
                if (ParameterSetName == "ById")
                {
                    ProcessById(Id);
                }
                else
                {
                    foreach (var name in Identity)
                    {
                        ProcessByName(name);
                    }
                }
            }
            catch (Exception ex)
            {
                var error = new ErrorRecord(
                    ex,
                    "ProcessingFailed",
                    ErrorCategory.InvalidOperation,
                    ParameterSetName == "ById" ? (object)Id : Identity);
                WriteError(error);
            }
        }

        protected override void EndProcessing()
        {
            WriteVerbose("Get-MyResource completed");
        }

        protected override void StopProcessing()
        {
            WriteVerbose("Get-MyResource stopped");
        }

        #endregion

        #region Private Methods

        private void ProcessById(int id)
        {
            var target = $"Resource ID {id}";

            if (ShouldProcess(target, "Retrieve resource"))
            {
                WriteVerbose($"Retrieving resource by ID: {id}");

                var resource = new MyResource
                {
                    Id = id,
                    Name = $"Resource{id}",
                    Status = "Active",
                    CreatedAt = DateTime.UtcNow,
                    Details = Detailed.IsPresent ? $"Detailed info for ID {id}" : null
                };

                WriteObject(resource);
            }
        }

        private void ProcessByName(string name)
        {
            var target = $"Resource '{name}'";

            if (ShouldProcess(target, "Retrieve resource"))
            {
                WriteVerbose($"Retrieving resource by name: {name}");

                // Simulate wildcard matching
                if (WildcardPattern.ContainsWildcardCharacters(name))
                {
                    var pattern = new WildcardPattern(name, WildcardOptions.IgnoreCase);

                    // Simulate multiple matches
                    for (int i = 1; i <= 3; i++)
                    {
                        var resourceName = $"{name.Replace("*", "")}_{i}";
                        if (pattern.IsMatch(resourceName))
                        {
                            WriteObject(CreateResource(i, resourceName));
                        }
                    }
                }
                else
                {
                    WriteObject(CreateResource(0, name));
                }
            }
        }

        private MyResource CreateResource(int id, string name)
        {
            return new MyResource
            {
                Id = id,
                Name = name,
                Status = "Active",
                CreatedAt = DateTime.UtcNow,
                Details = Detailed.IsPresent ? $"Detailed info for {name}" : null
            };
        }

        #endregion
    }

    /// <summary>
    /// MyResource data class.
    /// </summary>
    public class MyResource
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public string Details { get; set; }

        public override string ToString()
        {
            return $"{Name} (ID: {Id}, Status: {Status})";
        }
    }
}
