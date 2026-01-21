# 🔒 Terraform Dependency Lock File (.terraform.lock.hcl)

The lock file is our "Infrastructure Receipt." It ensures that every team member and our CI/CD pipeline use the exact same provider versions, preventing "works on my machine" bugs.

---

## 2. The Scenario: "Locking" the Version

Imagine it is Monday, and you run `terraform init`.

**Your Code:** Says `version = "~> 6.0"`.

**The Reality:** The latest version available today is **6.4.2**.

**The Action:** Terraform downloads **6.4.2** and automatically creates a file called `.terraform.lock.hcl`. Inside that file, it writes down:

> "I am currently using exactly 6.4.2."

---

## 3. Why is `.terraform.lock.hcl` file useful?

### 1) Avoids "Hidden" Updates

Imagine it is Tuesday, and the AWS team releases version **6.5.0**.

Without a lock file, if a coworker ran `terraform init` on their computer, they would get **6.5.0**.

Because you have the lock file, when your coworker runs `terraform init`, Terraform sees the "receipt" for **6.4.2** and says:

> "Wait, the lock file says we are using 6.4.2. I will download that version to match what my teammate used."

**Result:** Everyone on the team uses the exact same version, regardless of what new updates are released.

### 2) Security (Checksums)

The file stores hashes for multiple operating systems. This ensures that if you download the AWS provider on Windows, and your colleague downloads it on Linux, Terraform verifies both are legitimate copies from the official registry.

---

## 4. How to move forward: The `-upgrade` flag

If you actually want those new features in **6.5.0**, you have to give Terraform permission to break the lock. You do this by running:

```bash
terraform init -upgrade
```

### What this command does:

- It allows Terraform to update the locked provider version
- It looks at your code (`~> 6.0`) and checks the internet for the newest version that fits that rule
- It finds **6.5.0**, downloads it, and rewrites the lock file to say:

  > "The new locked version is 6.5.0."

---

## 5. What is inside the file?

When you run `terraform init`, Terraform generates this file in your root directory. It contains:

- **Provider Address:** The source of the provider (e.g., `registry.terraform.io/hashicorp/aws`)
- **Version:** The specific version that was actually downloaded (e.g., `5.60.0`)
- **Constraints:** The version rule you wrote in your `.tf` file (e.g., `~> 5.0`)
- **Hashes (H1/ZH):** Cryptographic signatures that prove the provider code hasn't been tampered with

### Example

If your `main.tf` has:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

Your `.terraform.lock.hcl` will look like this:

```hcl
# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.60.0"       # The exact version pinned
  constraints = "~> 5.0"       # The rule defined in your code
  hashes = [                   # Security fingerprints for different OS
    "h1:example123...",        # Mac Hash
    "zh:example456...",        # Windows Hash
  ]
}
```

---

## 6. Summary Table

| Step                 | Command                   | Result                                                                            |
| -------------------- | ------------------------- | --------------------------------------------------------------------------------- |
| First Time           | `terraform init`          | Downloads latest allowed version matching the constraint rule; Creates lock file. |
| New Version Released | `terraform init`          | Ignores the update; Stays on the version in the lock file.                        |
| Ready to Update      | `terraform init -upgrade` | Downloads the update; Updates the lock file.                                      |

---

## 7. Cross-Platform Support

Terraform providers are platform-specific. The file used for Windows is different from the file used for a Mac M1/M2 (Darwin) or Linux.

**The Problem:**
By default, `terraform init` only records the fingerprint for the computer you are currently using. If you are on Windows, the lock file only gets the Windows fingerprint. When your teammate on a Mac tries to run the code, their Terraform will say:

> "I have the Mac version, but I only see a Windows fingerprint in the lock file. I don't trust this!"

**The Solution:**
The command `terraform providers lock -platform=...` tells Terraform:

> "Go fetch the fingerprints for all these different systems and put them in the lock file now."

This allows the whole team to work regardless of their OS.

---

## 8. "Checksum Verification Failed" Error

This is a safety trigger. It is Terraform’s way of saying:

> "Something is different than what I expected, so I am stopping for your safety."

This error usually happens for three reasons:

- **Tampering:** (Rare) The provider file was actually modified or corrupted during download.
- **Missing Platform:** You are on a Mac, but the lock file only contains hashes for Windows. Terraform can't verify your version.
- **Manual Updates:** Someone manually changed the version number in the `main.tf` file but didn't run `terraform init -upgrade` to update the fingerprints.

---

### 8.1. What the "Checksum Verification Failed" Error Looks Like

```text
│ Error: Failed to install provider
│
│ Error query: registry.terraform.io/hashicorp/aws:
│ Checksum verification failed:
│ expected h1:abcdef123...
│ found    h1:987654321...
```

---

### 8.2. Breakdown of the Error

#### 8.2.1. The "Fingerprint" Comparison (Security)

- **Expected:** This is what is written in your `.terraform.lock.hcl`. It’s the "official record" your team agreed upon.
- **Found:** This is the fingerprint of the file actually sitting on your hard drive right now (currently downloaded provider).

**The Conflict:** Because they don't match, Terraform assumes the file is either malicious or the wrong version and refuses to use it.

#### 8.2.2. The Multi-OS Challenge (Cross-Platform)

Each operating system (Windows, Linux, macOS) gets a different zip file from HashiCorp.

- Windows Zip Hash: `h1:AAAA...`
- Linux Zip Hash: `h1:BBBB...`
- macOS Zip Hash: `h1:CCCC...`

If your `.terraform.lock.hcl` only contains `h1:AAAA`, your Linux build server will fail because it "found" `h1:BBBB` but "expected" `h1:AAAA`.

---

### 8.3. Fix when **Missing platform** is the reason

```bash
# Example: Adding Linux, Windows, and Mac (Intel/Silicon) hashes
terraform providers lock -platform=linux_amd64 -platform=windows_amd64 -platform=darwin_arm64 -platform=darwin_amd64
```

Result inside the file:

```hcl
provider "registry.terraform.io/hashicorp/aws" {
  version     = "6.0.0"
  constraints = "~> 6.0"
  hashes = [
    "h1:HashForWindows...", # Added for Windows
    "h1:HashForMac...",     # Added for Mac
    "h1:HashForLinux...",   # Added for Linux
  ]
}
```

---

### 8.4. Fix when **Manual updates** is the reason

1. Change the version in your `terraform {}` block.
2. Run the multi-platform lock command:

```bash
terraform providers lock \
  -platform=linux_amd64 \
  -platform=darwin_arm64 \
  -platform=windows_amd64
```

3. Run `terraform init`.
4. Commit both `main.tf` and `.terraform.lock.hcl` to Git.

---

## Platform Reference

| Operating System | Architecture | Terraform Platform String |
| ---------------- | ------------ | ------------------------- |
| Windows          | 64-bit       | windows_amd64             |
| Linux            | 64-bit       | linux_amd64               |
| Mac (Intel)      | 64-bit       | darwin_amd64              |
| Mac (M1/M2/M3)   | ARM          | darwin_arm64              |

---

## Summary Table: When to do what?

| Situation                       | Action                                                              |
| ------------------------------- | ------------------------------------------------------------------- |
| Normal development              | Just run `terraform init`.                                          |
| Upgrading to a new version      | Run `terraform init -upgrade`.                                      |
| New teammate has a different OS | Run `terraform providers lock -platform=...`.                       |
| Checksum Error appears          | Check if someone updated the `.tf` file without running `-upgrade`. |

---

## 9. Best Practices (Official Guidelines)

- **Commit to Git:** You must check `.terraform.lock.hcl` file into version control (GitHub/GitLab).
- **The `.terraform` Directory:** The `.terraform.lock.hcl` is committed, but the `.terraform/` folder must be ignored via `.gitignore`.
- **Don't Edit Manually:** This file is managed by Terraform. Manual edits usually cause checksum failures.
- **CI/CD Parity:** Ensure your CI/CD runner (usually Linux) has its hash recorded using `-platform=linux_amd64`.
- **Review Changes:** Review lock file changes in Pull Requests.
- **Cross-Platform Support:** Use `terraform providers lock -platform=windows_amd64 -platform=darwin_arm64` when needed.

**Important Note:** You should always commit the `.terraform.lock.hcl` file to your Version Control (like Git). This is what keeps your entire team in sync!
