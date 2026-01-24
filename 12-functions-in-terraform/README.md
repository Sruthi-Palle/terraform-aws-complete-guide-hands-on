# Terraform Functions

### Functional Definition and Logic

In Terraform, functions are used to transform data, perform calculations, and manipulate strings or collections during the infrastructure provisioning process. Whereas, In a general programming context, a function is a block of code designed to perform a specific task, allowing for the reuse of logic without duplicating code.

### HCL vs. General Programming

Terraform uses HCL (HashiCorp Configuration Language). While it offers programmatic-like features, it has specific limitations:

- **No Custom Functions:** Unlike languages like Python or JavaScript, users cannot define their own functions in Terraform.
- **Lack of OOP Features:** HCL does not support classes, objects, or traditional inheritance.
- **Inbuilt Library:** All functional logic must be derived from Terraform's native library, which is categorized into types such as validation, lookup, date/time, and collection.

---

## Categorization of Inbuilt Functions

### String Manipulation Functions

String functions are used to format and modify text data, which is critical for resource naming and labeling.

| **Function** | **Description**                                      | **Example**                               |
| ------------ | ---------------------------------------------------- | ----------------------------------------- |
| `upper()`    | Converts string to uppercase.                        | `upper("web")` → `"WEB"`                  |
| `lower()`    | Converts string to lowercase.                        | `lower("WEB")` → `"web"`                  |
| `trim()`     | Removes specific characters/spaces from ends.        | `trim("!hi!", "!")` → `"hi"`              |
| `replace()`  | Replaces substrings.                                 | `replace("1.0.0", ".", "-")` → `"1-0-0"`  |
| `split()`    | Produces a list by dividing a string by a delimiter. | `split(",", "a,b,c")` → `["a", "b", "c"]` |

### Numeric and Collection Functions

These functions handle mathematical operations and the manipulation of lists and maps.

- **Numeric:**
  - `max()`: Returns the highest number from a set.
  - `min()`: Returns the lowest number from a set.
  - `abs()`: Returns the absolute value of a number (e.g., `-42` becomes `42`).
  - `sum()`: Actually, Terraform **does** have a `sum()` function (added in version 0.12+). It takes a list or set of numbers and returns their sum.
    _Example:_ `sum([1, 2, 3])` → `6`.
- **Collection:**
  - `length()`: Determines the number of elements in a list or characters in a string.
  - `concat()`: Merges two or more lists into a single list. It does not work on strings directly.
  - `merge()`: Combines two or more maps (key-value pairs) into a single map. If duplicate keys exist, the last one processed takes precedence.

### Type Conversion and Utility Functions

- **Type Conversion:**
  - `toset()`: Converts a list to a set, effectively removing any duplicate values.
  - `tonumber()`: Converts a string containing a numeric value into an actual number type.
  - `tostring()`: Converts a numeric or boolean value into a string.
- **Date and Time:**
  - `timestamp()`: Returns the current date and time in a predefined UTC format.
  - `formatdate()`: Formats a timestamp into a user-specified layout (e.g., `"DD MM YYYY"`).

### Logic & Error Handling

- `lookup(map, key, default)`: Retrieves a value from a map. If the key is missing, it returns the default.
- `try(expr, fallback)`: Returns the first expression that doesn't result in an error. Great for optional variables.
- `can(expr)`: Returns a boolean. Useful for checking if a value is valid without failing the run.

### The Spread Operator

When using functions like `max()` or `min()`, Terraform expects individual numeric arguments rather than a single list or tuple. To address this, the **spread operator** (`...`) is used.

- **Example:** `max(local.positive_cost...)` expands a list into individual arguments so the function can process them.

---

## Vadilation Functions:

Terraform allows for pre-validation of variables to ensure that inputs meet specific requirements before infrastructure is provisioned. **This is handled within the** `variable` **block using a** `validation` **sub-block.**

### Validation Structure

A validation block requires two primary attributes:

1. `condition`: A boolean expression that must evaluate to `true` for the input to be accepted.
2. `error_message`: A string that is displayed to the user if the condition evaluates to `false`.

   ```yaml
   variable "instance_type" {
   type = string
   validation {
   condition     = can(regex("^t[2-3]\\.", var.instance_type))
   error_message = "Only t2 or t3 instances are allowed."
   }
   }
   ```

### Key Validation Functions and Logic

| Function/Operator  | Description                                      | Application Example                                                                    |
| ------------------ | ------------------------------------------------ | -------------------------------------------------------------------------------------- |
| `length()`         | Measures the number of characters or elements.   | Ensuring an instance type string is between 2 and 20 characters.                       |
| `&&` (Logical AND) | Combines multiple conditions.                    | Validating that a string meets both a minimum and maximum length.                      |
| `can(regex())`     | Checks if a string matches a regular expression. | Restricting instance types to those starting with "t2" or "t3" (e.g., `^t[2-3]\\..*`). |
| `ends_with()`      | Validates the suffix of a string.                | Enforcing that a backup name ends specifically with `_backup`.                         |

---

## Management of Sensitive Data

To prevent the exposure of confidential information (such as credentials), Terraform provides the `sensitive` attribute.

- **Implementation:** Setting `sensitive = true` **within a variable declaration** prevents its value from being printed in the terminal (stdout) during `terraform plan` or `terraform apply`.
- **Output Requirements:** If an output refers to a sensitive variable, the output itself must also be marked as `sensitive = true`.
- **Caveats:** While the value is obscured in the logs, it is not encrypted. It remains stored in the Terraform state file in a readable format (often Base64 encoded).

---

## Date, Time, and File Handling

Terraform can interact with the system environment and external files to create dynamic configurations.

### Timestamp and Formatting

`timestamp()`:

- Generates the current UTC time. Note that the value is often marked as "known after apply" because it is generated at the moment of execution.
- **Behaviour:** It is important to note that `timestamp()` changes **every time** you run `terraform apply`. This can cause resources to "drift" or trigger updates on every run (like changing a tag every time). To avoid this, people often use it with `lifecycle { ignore_changes = [tags] }`

`formatdate()`:

- Converts a timestamp into a human-readable format.
- Example format: `"YYYY-MM-DD"`.
- Specific month formatting (e.g., `"MON"`) can be used to print three-letter month abbreviations in uppercase.

### File Operations

Terraform can read and parse external files to populate variables or locals.

- `fileexists()`: Checks for the presence of a file at a specified path, returning a boolean.
- `file()`: Reads the raw content of a file as a string.
- `jsondecode()`: Converts a JSON-formatted string into a Terraform map or object, allowing developers to access specific keys (e.g., database host or port) from a `.json` configuration file.

**Dynamic Configuration Logic Example:** A common pattern involves checking for a file's existence before attempting to read it: `local.config_file_exists ? jsondecode(file("config.json")) : ""`

---

## Practical Implementation in Terraform Configurations

### The Role of Locals and Interpolation

Functions are frequently implemented within `locals` blocks to process variables before they are used in resource definitions. This allows for centralized data transformation.

**String Interpolation:** When concatenating variables or function results with other strings, Terraform uses the syntax `${...}`. For example: `"port-${local.port_number}"`.

### Real-World Use Cases

#### 1\. Standardizing S3 Bucket Naming

AWS S3 has strict naming requirements (lowercase, no spaces, length between 3 and 63 characters). Multiple functions can be chained to ensure compliance:

- Use `lower()` to enforce lowercase.
- Use `replace()` to swap spaces or special characters with hyphens.
- Use `substr()` to ensure the name does not exceed 63 characters.

```yaml
# Example of function nesting (Chaining)
resource "aws_s3_bucket" "example" {
bucket = substr(lower(replace(var.project_name, " ", "-")), 0, 63)
}
```

#### 2\. Dynamic Tagging Strategy

Organizations often use a mix of global default tags and environment-specific tags. The `merge()` function allows for the consolidation of these maps:

```yaml
tags = merge(var.default_tags, var.environment_tags)
```

This ensures resources receive all necessary metadata from different variable sources.

#### 3\. Transforming Strings into Structured Rules

When input data is provided as a comma-separated string (e.g., `"80,443,8080"`), Terraform can transform this into a manageable list:

- **Step 1:** Use `split(",", var.allowed_ports)` to create a list.
- **Step 2:** Use a `for` expression to iterate through the list and generate a map of security group rules, including dynamic names and descriptions.
- ```yaml
    locals {
    # Split comma-separated ports into list

    # Create security group rules data structure
       port_list = split(",", var.allowed_ports)
       sg_rules = [for port in local.port_list : {
         name        = "port-${port}"
         port        = port
         description = "Allow traffic on port ${port}"
       }]
       formatted_ports = join("-", [for port in local.port_list : "port-${port}"])
    }

    # Format for documentation: "port-80-port-443-port-8080-port-3306"
  ```

---

## Key takeaways include:

- **Purpose and Efficiency:** Functions facilitate code reuse and logic application within configuration files, reducing redundancy and execution time.
- **Inbuilt Constraint:** Users must rely exclusively on Terraform's predefined functions; the language does not support Object-Oriented Programming (OOP) concepts or custom function definitions.
- **Testing Environment:** The `terraform console` provides a built-in interactive shell for testing function logic without requiring the creation of configuration files.
- **Practical Utility:** Functions are essential for enforcing infrastructure naming conventions (e.g., S3 bucket constraints), merging resource tags, and transforming raw input data into structured configuration objects.Variable Validation and Constraint Enforcement

- **Variable Validations:** Utilizing the `validation` block to enforce naming conventions and input constraints at the variable declaration level.
- **Data Security:** Implementing the `sensitive` attribute to protect confidential information from CLI logs and standard output.
- **Complex Data Operations:** Leveraging `for` loops and the spread operator (`...`) to perform numeric operations on lists and tuples.
- **External Data Integration:** Using file handling and JSON decoding functions to dynamically incorporate external configuration files into the Terraform state.
