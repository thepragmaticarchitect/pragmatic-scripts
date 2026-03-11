🏗️ Public Shared Scripts

Practical automation for the Pragmatic Architect.

This repository is a curated collection of multi-language utility scripts designed for infrastructure reporting, cloud automation, and operational efficiency. It covers Bash, Python, and PowerShell, organized by functional domain.
📂 Repository Structure

The library is organized first by Language, then by Domain, ensuring a clean environment for linting and dependencies.
🐚 Bash

    networking/backup_elbs.sh: Discovers ALBs, NLBs, and CLBs; exports configurations to JSON and syncs to S3.

    security/rotate_keys.sh: Utility for IAM access key rotation.

🐍 Python

    compute/ec2_idle_finder.py: Identifies underutilized EC2 resources for cost optimization using Boto3.

    storage/s3_analyzer.py: Reports on bucket sizes and lifecycle policy gaps.

💙 PowerShell

    database/Get-DBUserReport.ps1: Extracts and formats database user access information.

    reporting/HTMLTable.ps1: A reusable helper for converting object output into clean HTML tables for email reports.

🚀 Why This Repo Exists

In a modern cloud environment, a "Pragmatic Architect" doesn't stick to one tool. This repo exists to:

    Solve Real Problems: No "Hello World" scripts; only tools that solve actual operational pain points.

    Demonstrate Polyglot Skills: Showcasing proficiency across different execution environments.

    Standardize Reporting: Moving away from raw CLI output toward structured JSON and HTML reports.

🛠️ Requirements & Setup

Each language directory contains its own specific requirements:

    Bash: Requires aws-cli and jq.

    Python: Requires python 3.9+ and pip install -r python/requirements.txt.

    PowerShell: Requires PS 5.1+ or PS Core 7+.

📝 Notes & Disclaimer

These scripts are shared as functional patterns. Always review code and test in a lower environment (Sandbox/Dev) before running against production infrastructure.