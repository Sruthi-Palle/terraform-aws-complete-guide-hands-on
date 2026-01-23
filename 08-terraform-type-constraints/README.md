# Taxonomy of Terraform Variables

Terraform variables are generally classified by their purpose or the value they contain. While purpose-based variables include input, output, and local variables, value-based variables—known as type constraints—dictate how data is structured and validated.

---

## Primitive Types

Primitive types are straightforward, single-value constraints:

- **String**: Sequences of characters enclosed in double quotes (e.g., "p", "us-east-1").

- **Number**: Numeric values used for counts, ages, or port numbers (e.g., 1, 443). In Terraform, the number type represents both integers (like 10) and floats (like 10.5).

- **Bool (Boolean)**: Logical values representing either true or false. These are often used for conditional arguments like monitoring or associate_public_ip_address.

---

## Complex Types

Complex types allow for the storage of multiple values within a single variable. They are further divided into collection types and structural types.

| Type   | Format               | Key Characteristics                                                                |
| ------ | -------------------- | ---------------------------------------------------------------------------------- |
| List   | `list(<type>)`       | Ordered collection; allows duplicates; accessed via zero-based index.              |
| Set    | `set(<type>)`        | Unordered collection; no duplicates; requires conversion to list for index access. |
| Map    | `map(<type>)`        | Key-value pairs; all values must share the same data type.                         |
| Tuple  | `tuple([<types>])`   | Ordered list with fixed positions for different data types.                        |
| Object | `object({<schema>})` | Key-value pairs where each key can have a distinct data type.                      |

---

## Detailed Analysis of Collection Types

### Lists and Indexing

A List is a collection of values that share the same data type. Because the order is fixed, elements are accessed using a zero-based index.

- **Example Usage**: Storing allowed VM types (`["t2.micro", "t2.small"]`).

- **Access Syntax**: `var.allowed_vm_types[1]` would return `"t2.small"`.

- **Duplicates**: Lists natively support duplicate entries without error.

```hcl
# List type - IMPORTANT: Allows duplicates, maintains order
variable "allowed_cidr_blocks" {
    type = list(string)
    description = "list of allowed cidr blocks for security group"
    default = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
    # Access: var.allowed_cidr_blocks[0] = "10.0.0.0/8"
    # Can have duplicates: ["10.0.0.0/8", "10.0.0.0/8"] is valid
}
```

---

### Sets and Unique Constraints

Sets are similar to lists but enforce uniqueness. If duplicate values are entered, they are automatically removed.

- **Access Limitation**: Elements in a set do not have a fixed index. To access a specific element by index, the set must be wrapped in a conversion function: `tolist(var.set_name)[index]`.

- **Primary Use**: When the uniqueness of the elements is more critical than their specific order.

```hcl
# Set type - IMPORTANT: No duplicates allowed, order doesn't matter
variable "availability_zones" {
    type = set(string)
    description = "set of availability zones (no duplicates)"
    default = ["us-east-1a", "us-east-1b", "us-east-1c"]
    # KEY DIFFERENCE FROM LIST:
    # - Automatically removes duplicates
    # - Order is not guaranteed
    # - Cannot access by index like set[0] - need to convert to list first
}
```

---

### Maps for Key-Value Pairs

Maps are used to store data in key-value formats where every value must be of the same type (e.g., a map of strings).

- **Example Usage**: Resource tagging.

- **Access Syntax**: Values are accessed via their keys (e.g., `var.tags["environment"]`).

```hcl
# Map type - IMPORTANT: Key-value pairs, keys must be unique
variable "instance_tags" {
    type = map(string)
    description = "tags to apply to the ec2 instances"
    default = {
        "Environment" = "dev"
        "Project" = "terraform-course"
        "Owner" = "devops-team"
    }
    # Access: var.instance_tags["Environment"] = "dev"
    # Keys are always strings, values must match the declared type
}
```

---

## Detailed Analysis of Structural Types

### Tuples

Tuples function as lists that can contain multiple different data types. However, the sequence and type of each element must match the defined constraint exactly.

- **Definition Example**: `type = tuple([number, string, number])`.

- **Validation**: If the definition expects a number at index 0 and a string at index 1, the default values must strictly follow this order (e.g., `[443, "TCP", 443]`).

```hcl
# Tuple type - IMPORTANT: Fixed length, each position has specific type
variable "network_config" {
    type = tuple([string, string, number])
    description = "Network configuration (VPC CIDR, subnet CIDR, port number)"
    default = ["10.0.0.0/16", "10.0.1.0/24", 80]
    # CRITICAL RULES:
    # - Position 0 must be string (VPC CIDR)
    # - Position 1 must be string (subnet CIDR)
    # - Position 2 must be number (port)
    # - Cannot add/remove elements - length is fixed
    # Access: var.network_config[0], var.network_config[1], var.network_config[2]
}
```

---

### Objects

Objects are the most flexible complex type, allowing for a collection of diverse data types identified by keys. This is ideal for grouping related configuration metadata.

- **Example Configuration**: An object representing a resource `"config"` might include:
  - region (String)
  - monitoring (Bool)
  - instance_count (Number)

- **Access Syntax**: Accessed via dot notation: `var.config.region`.

```hcl
# Object type - IMPORTANT: Named attributes with specific types
variable "server_config" {
    type = object({
        name = string
        instance_type = string
        monitoring = bool
        storage_gb = number
        backup_enabled = bool
    })
    description = "Complete server configuration object"
    default = {
        name = "web-server"
        instance_type = "t2.micro"
        monitoring = true
        storage_gb = 20
        backup_enabled = false
    }
    # KEY BENEFITS:
    # - Self-documenting structure
    # - Type safety for each attribute
    # - Access: var.server_config.name, var.server_config.monitoring
    # - All attributes must be provided (unless optional)
}
```

---

## Special Type Constraints

Terraform includes two special designations for variables that do not fit strictly into the categories above:

- **Null**: Represents an absence of value. Storing a null value reserves memory space but indicates that the variable is intentionally empty.

- **Any**: A placeholder that allows the variable to accept any data type. Terraform will automatically determine the type based on the value provided. While flexible, it is generally less secure for strict data validation than specific constraints.

---

## Technical Implementation Insights

### Data Conversion for sets

When working with sets, users must be aware that direct index access is prohibited. The `tolist()` function is the required workaround for index-based retrieval from a set.

### Variable Interpolation Restrictions

Within Terraform, variables cannot typically be used to define the default values of other variables. Static values or locals are the preferred methods for initializing these complex structures.

### Practical Resource Mapping

- **Count Argument**: Requires a number type.

- **Security Group Rules**: Often utilize `list(string)` for CIDR blocks or tuple for port configurations (from-port, protocol, to-port).

- **Tags**: Standardly implemented as a `map(string)` to provide metadata like "Environment" or "CreatedBy".

---

## Summary

In Terraform, type constraints define the nature of values stored within variables. These constraints are categorized into two primary groups: Primitive types (String, Number, Bool) and Complex types (List, Set, Map, Object, Tuple). Utilizing specific type constraints ensures data integrity and enables the creation of manageable, reusable infrastructure code.
