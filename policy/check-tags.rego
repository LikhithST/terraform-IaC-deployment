package terraform.tags

import future.keywords.in

# List of resource types to check. Add or remove types as needed.
monitored_resources := [
    "aws_instance",
    "aws_s3_bucket",
    "aws_vpc",
    "aws_security_group"
]

# Set of rule violations
deny[msg] {
    # Traverse planned resource changes
    resource := input.resource_changes[_]

    # Filter to only monitored resource types
    resource.type in monitored_resources

    # Ignore resource deletions
    not "delete" in resource.change.actions

    # Check for missing tag or incorrect value
    tags := object.get(resource.change.after, "tags", {})
    not tags["iac-tool"] == "terraform"

    msg := sprintf(
        "Resource '%v' of type '%v' must have tag 'iac-tool' set to 'terraform'. Found: '%v'",
        [resource.address, resource.type, object.get(tags, "iac-tool", "MISSING")]
    )
}