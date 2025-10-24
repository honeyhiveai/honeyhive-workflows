#!/usr/bin/env python3
"""
Stack selector based on deployment type.
Loads deployment type configurations from YAML files for maintainability.
Uses rich for beautiful terminal output and click for CLI.
"""

import sys
import os
import yaml
from pathlib import Path
from typing import Dict, Optional, Tuple, List
import glob

try:
    import click
except ImportError:
    print("Error: 'click' library is not installed")
    print("Install with: pip install click")
    sys.exit(1)

try:
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich.tree import Tree
    from rich.syntax import Syntax
    from rich.markdown import Markdown
    from rich.columns import Columns
    from rich.text import Text
    from rich import print as rprint
    from rich.layout import Layout
    from rich.prompt import Confirm
except ImportError:
    print("Error: 'rich' library is not installed")
    print("Install with: pip install rich")
    print("Or: pip install pyyaml rich click")
    sys.exit(1)

# Initialize rich console
console = Console()


class StackSelector:
    """Handles loading and selecting deployment stacks."""

    def __init__(self):
        """Initialize the stack selector."""
        self.script_dir = Path(__file__).parent.parent
        self.config_dir = self.script_dir / "stacks" / "deployment-types" / "configs"
        self.deployment_stacks = {}
        self.load_deployment_configs()

    def load_deployment_configs(self):
        """Load all deployment type configurations from YAML files."""
        if not self.config_dir.exists():
            console.print(
                f"[red]❌ Error: Deployment configs directory not found:[/red] {self.config_dir}"
            )
            raise click.ClickException(f"Config directory not found: {self.config_dir}")

        # Find all YAML config files
        config_files = list(self.config_dir.glob("*.yaml")) + list(
            self.config_dir.glob("*.yml")
        )

        if not config_files:
            console.print(
                "[red]❌ Error: No deployment configuration files found[/red]"
            )
            raise click.ClickException("No deployment configuration files found")

        # Load each config file
        with console.status(
            "[bold green]Loading deployment configurations..."
        ) as status:
            for config_file in config_files:
                try:
                    with open(config_file, "r") as f:
                        config = yaml.safe_load(f)
                        if config and "name" in config:
                            # Skip disabled configurations
                            if config.get("enabled", True):
                                self.deployment_stacks[config["name"]] = config
                                status.update(f"[green]Loaded {config['name']}[/green]")
                            else:
                                console.print(
                                    f"[yellow]  Skipping disabled config: {config['name']}[/yellow]"
                                )
                except yaml.YAMLError as e:
                    console.print(
                        f"[yellow]  Warning: Failed to load {config_file}: {e}[/yellow]"
                    )
                except Exception as e:
                    console.print(
                        f"[yellow]  Warning: Error loading {config_file}: {e}[/yellow]"
                    )

        if not self.deployment_stacks:
            console.print(
                "[red] Error: No valid deployment configurations loaded[/red]"
            )
            raise click.ClickException("No valid deployment configurations loaded")

        console.print(
            f"[green]✓ Loaded {len(self.deployment_stacks)} deployment configurations[/green]"
        )

    def get_deployment_type(self, config: Dict) -> str:
        """Extract deployment type from configuration."""
        deployment_type = config.get("deployment_type")

        if not deployment_type:
            console.print(
                "[yellow]  Warning: deployment_type not specified in configuration[/yellow]"
            )
            console.print("   Defaulting to 'full_stack'")
            return "full_stack"

        if deployment_type not in self.deployment_stacks:
            console.print(
                f"[red] Error: Unknown deployment type: {deployment_type}[/red]"
            )
            console.print(
                f"   Valid types: {', '.join(sorted(self.deployment_stacks.keys()))}"
            )
            raise click.ClickException(f"Unknown deployment type: {deployment_type}")

        return deployment_type

    def display_deployment_info(self, deployment_type: str):
        """Display information about the selected deployment type using rich."""
        info = self.deployment_stacks[deployment_type]

        # Create main panel
        panel = Panel.fit(
            f"[bold cyan]{info.get('description', 'N/A')}[/bold cyan]",
            title=f"Deployment Type: [bold green]{deployment_type}[/bold green]",
            border_style="cyan",
        )
        console.print(panel)

        # Create a tree for components and features
        tree = Tree("Configuration")

        # Add components
        if "components" in info:
            comp_branch = tree.add("Components")
            for component in info["components"]:
                comp_branch.add(f"[green]✓[/green] {component}")

        # Add enabled features
        if "features" in info:
            feat_branch = tree.add("Enabled Features")
            for feature in info["features"]:
                feat_branch.add(f"[green]•[/green] {feature}")

        # Add disabled features
        if "disabled_features" in info:
            disabled_branch = tree.add("Disabled Features")
            for feature in info["disabled_features"]:
                disabled_branch.add(f"[dim]x {feature}[/dim]")

        console.print(tree)

        # Create tables for detailed configurations
        if "cluster_config" in info:
            cluster = info["cluster_config"]
            table = Table(
                title="Cluster Configuration",
                show_header=True,
                header_style="bold magenta",
            )
            table.add_column("Property", style="cyan", no_wrap=True)
            table.add_column("Value", style="white")

            if "node_instance_types" in cluster:
                table.add_row("Node Types", ", ".join(cluster["node_instance_types"]))
            table.add_row("Min Nodes", str(cluster.get("min_nodes", "N/A")))
            table.add_row("Max Nodes", str(cluster.get("max_nodes", "N/A")))
            table.add_row("Desired Nodes", str(cluster.get("desired_nodes", "N/A")))
            if cluster.get("spot_enabled"):
                table.add_row("Spot Usage", f"{cluster.get('spot_percentage', 0)}%")

            console.print(table)

        # Network configuration
        if "subnet_config" in info:
            subnet = info["subnet_config"]
            net_table = Table(
                title="Network Configuration",
                show_header=True,
                header_style="bold blue",
            )
            net_table.add_column("Property", style="cyan")
            net_table.add_column("Value", style="white")

            net_table.add_row("Availability Zones", str(subnet.get("count", "N/A")))
            net_table.add_row("NAT Strategy", subnet.get("nat_strategy", "N/A"))
            net_table.add_row(
                "Public Subnet Bits", str(subnet.get("public_newbits", "N/A"))
            )
            net_table.add_row(
                "Private Subnet Bits", str(subnet.get("private_newbits", "N/A"))
            )

            console.print(net_table)

        # Special configurations
        if "security" in info:
            security = info["security"]
            sec_panel = Panel(
                f"Encryption: [yellow]{security.get('encryption', 'N/A')}[/yellow]\n"
                f"Compliance: [green]{', '.join(security.get('compliance', []))}[/green]",
                title="Security Configuration",
                border_style="red",
            )
            console.print(sec_panel)

        if "hybrid_config" in info:
            hybrid = info["hybrid_config"]
            hybrid_panel = Panel(
                f"Control Plane: [blue]{hybrid.get('control_plane_endpoint', 'N/A')}[/blue]\n"
                f"Telemetry Forward: [yellow]{hybrid.get('telemetry_forward', False)}[/yellow]",
                title="Hybrid Configuration",
                border_style="magenta",
            )
            console.print(hybrid_panel)

    def get_stack_file(self, deployment_type: str) -> Optional[str]:
        """Get the stack file path for the deployment type."""
        stack_info = self.deployment_stacks[deployment_type]
        stack_file = stack_info.get("stack_file")

        if not stack_file:
            console.print(
                f"[red] Error: Stack file not configured for {deployment_type}[/red]"
            )
            if not stack_info.get("enabled", True):
                console.print(
                    "   [dim]This deployment type is not yet implemented[/dim]"
                )
            return None

        # Check if stack file exists
        stack_path = self.script_dir / stack_file

        if not stack_path.exists():
            console.print(
                f"[yellow]  Warning: Stack file not found: {stack_file}[/yellow]"
            )
            console.print(f"   Expected at: {stack_path}")
            return stack_file  # Return anyway for use in commands

        return stack_file

    def list_available_types(self):
        """List all available deployment types using rich table."""
        # Create a table
        table = Table(
            title="Available Deployment Types",
            show_header=True,
            header_style="bold magenta",
        )
        table.add_column("Status", justify="center", style="green", no_wrap=True)
        table.add_column("Type", style="cyan", no_wrap=True)
        table.add_column("Description", style="white")
        table.add_column("Key Features", style="yellow")

        # Sort by name for consistent output
        for dtype in sorted(self.deployment_stacks.keys()):
            info = self.deployment_stacks[dtype]
            stack_file = info.get("stack_file")
            status = "[green]OK[/green]" if stack_file else "[yellow]Pending[/yellow]"
            desc = info.get("description", "No description")

            # Show key features
            features = ""
            if "features" in info:
                feat_list = info["features"][:3]  # Show first 3 features
                features = ", ".join(feat_list)
                if len(info["features"]) > 3:
                    features += f" [dim](+{len(info['features'])-3} more)[/dim]"

            table.add_row(status, dtype, desc, features)

        console.print(table)

    def export_config(self, config_file: str, deployment_type: str):
        """Display export commands for automation using rich."""
        config_path = Path(config_file).absolute()
        stack_info = self.deployment_stacks[deployment_type]
        stack_file = stack_info.get("stack_file", "")

        # Create deployment commands panel
        commands = []

        # Environment setup
        commands.append("[bold cyan]1. Set environment:[/bold cyan]")
        commands.append(f'   [green]export TENANT_CONFIG_PATH="{config_path}"[/green]')

        if stack_file:
            commands.append("")
            commands.append("[bold cyan]2. Initialize stack:[/bold cyan]")
            commands.append(
                f"   [green]terragrunt stack init --stack {stack_file}[/green]"
            )

            commands.append("")
            commands.append("[bold cyan]3. Plan deployment:[/bold cyan]")
            commands.append(
                f"   [green]terragrunt stack plan --stack {stack_file}[/green]"
            )

            commands.append("")
            commands.append("[bold cyan]4. Apply deployment:[/bold cyan]")
            commands.append(
                f"   [green]terragrunt stack apply --stack {stack_file}[/green]"
            )

        commands_text = "\n".join(commands)
        commands_panel = Panel(
            commands_text,
            title="Deployment Commands",
            border_style="green",
            expand=False,
        )
        console.print(commands_panel)

        # Automation exports
        exports = []
        exports.append(f'[blue]export SELECTED_STACK="{stack_file}"[/blue]')
        exports.append(f'[blue]export DEPLOYMENT_TYPE="{deployment_type}"[/blue]')

        # Export additional configuration
        if "cluster_config" in stack_info:
            cluster = stack_info["cluster_config"]
            exports.append(
                f"[blue]export NODE_MIN={cluster.get('min_nodes', 1)}[/blue]"
            )
            exports.append(
                f"[blue]export NODE_MAX={cluster.get('max_nodes', 10)}[/blue]"
            )

        exports_text = "\n".join(exports)
        exports_panel = Panel(
            exports_text,
            title="🤖 Automation Exports",
            border_style="blue",
            expand=False,
        )
        console.print(exports_panel)


def display_config_summary(config: Dict):
    """Display summary of the configuration using rich table."""
    # Create configuration table
    table = Table(title=" Configuration Summary", show_header=False, show_edge=True)
    table.add_column("Property", style="cyan", no_wrap=True)
    table.add_column("Value", style="white")

    table.add_row("Organization", config.get("org", "N/A"))
    table.add_row("Environment", config.get("env", "N/A"))
    table.add_row(
        "Region", f"{config.get('region', 'N/A')} ({config.get('sregion', 'N/A')})"
    )
    table.add_row("Deployment", config.get("deployment", "N/A"))
    table.add_row("Account ID", config.get("account_id", "N/A"))
    table.add_row(
        "Deployment Type",
        f"[bold green]{config.get('deployment_type', 'full_stack')}[/bold green]",
    )

    # Optional settings
    if "vpc_cidr" in config:
        table.add_row("VPC CIDR", config["vpc_cidr"])
    if "domain_name" in config:
        table.add_row("Domain", config["domain_name"])

    console.print(table)


def load_config(config_file: str) -> Dict:
    """Load and parse YAML configuration file."""
    try:
        with open(config_file, "r") as f:
            config = yaml.safe_load(f)
            if not config:
                raise ValueError("Empty configuration file")
            return config
    except FileNotFoundError:
        console.print(
            f"[red] Error: Configuration file not found: {config_file}[/red]"
        )
        raise click.ClickException(f"Configuration file not found: {config_file}")
    except yaml.YAMLError as e:
        console.print(f"[red] Error: Invalid YAML in configuration file:[/red]")
        console.print(f"  {e}")
        raise click.ClickException("Invalid YAML in configuration file")
    except Exception as e:
        console.print(f"[red] Error loading configuration: {e}[/red]")
        raise click.ClickException(f"Error loading configuration: {e}")


def validate_config(config: Dict) -> Tuple[bool, List[str]]:
    """Validate the configuration has required fields."""
    required_fields = ["org", "env", "region", "deployment", "account_id"]
    missing_fields = []

    for field in required_fields:
        if field not in config or not config[field]:
            missing_fields.append(field)

    if missing_fields:
        return False, missing_fields
    return True, []


@click.command(context_settings=dict(help_option_names=["-h", "--help"]))
@click.argument("config_file", type=click.Path(exists=True), required=False)
@click.option(
    "--list", "list_types", is_flag=True, help="List all available deployment types"
)
@click.option("--deployment-type", "-t", help="Override deployment type in config")
@click.option(
    "--export", "-e", is_flag=True, help="Export environment variables for automation"
)
@click.option(
    "--json", "output_json", is_flag=True, help="Output in JSON format (for automation)"
)
@click.option(
    "--validate-only",
    is_flag=True,
    help="Only validate the configuration without displaying",
)
@click.option(
    "--show-config-dir", is_flag=True, help="Show the deployment configs directory path"
)
@click.version_option(version="1.0.0", prog_name="Stack Selector")
@click.pass_context
def main(
    ctx,
    config_file,
    list_types,
    deployment_type,
    export,
    output_json,
    validate_only,
    show_config_dir,
):
    """
    Stack Selector - Choose the right Terragrunt stack based on deployment type.

    This tool helps select and configure the appropriate Terragrunt stack
    for different deployment scenarios (control plane, data plane, BYOC, etc.).

    Examples:

        \b
        # Select stack for a configuration
        select-stack.py configs/production.yaml

        \b
        # List all available deployment types
        select-stack.py --list

        \b
        # Override deployment type
        select-stack.py configs/test.yaml --deployment-type control_plane

        \b
        # Export environment variables
        select-stack.py configs/prod.yaml --export

        \b
        # Validate configuration only
        select-stack.py configs/staging.yaml --validate-only
    """

    # Initialize selector
    try:
        selector = StackSelector()
    except click.ClickException:
        ctx.exit(1)

    # Handle special options first
    if show_config_dir:
        console.print(f"[cyan]Configuration directory: {selector.config_dir}[/cyan]")
        ctx.exit(0)

    if list_types:
        selector.list_available_types()
        console.print(
            f"\n[cyan]Configuration files loaded from: {selector.config_dir}[/cyan]"
        )
        console.print(
            f"\n💡 [green]To add or modify deployment types, edit files in:[/green]"
        )
        console.print(f"   {selector.config_dir}")
        ctx.exit(0)

    # Require config file for other operations
    if not config_file:
        console.print(
            "[red]Error: CONFIG_FILE is required unless using --list or --help[/red]"
        )
        console.print("\nUse --help for usage information")
        ctx.exit(1)

    # Load configuration
    with console.status(
        f"[bold green]Loading configuration: {config_file}[/bold green]"
    ):
        try:
            config = load_config(config_file)
        except click.ClickException:
            ctx.exit(1)

    # Validate configuration
    valid, missing = validate_config(config)
    if not valid:
        console.print("[red] Error: Missing required fields in configuration:[/red]")
        for field in missing:
            console.print(f"   [red]• {field}[/red]")
        ctx.exit(1)

    # Override deployment type if specified
    if deployment_type:
        config["deployment_type"] = deployment_type
        console.print(
            f"[yellow]  Overriding deployment type to: {deployment_type}[/yellow]"
        )

    # Get deployment type
    try:
        deployment_type = selector.get_deployment_type(config)
    except click.ClickException:
        ctx.exit(1)

    # If validate-only, exit here
    if validate_only:
        console.print(f"[green] Configuration is valid[/green]")
        console.print(f"   Deployment type: {deployment_type}")
        ctx.exit(0)

    # JSON output for automation
    if output_json:
        import json

        stack_file = selector.get_stack_file(deployment_type)
        output = {
            "deployment_type": deployment_type,
            "stack_file": stack_file,
            "config_path": str(Path(config_file).absolute()),
            "account_id": config.get("account_id"),
            "region": config.get("region"),
            "environment": config.get("env"),
        }
        console.print(json.dumps(output, indent=2))
        ctx.exit(0)

    console.print()  # Add spacing

    # Display configuration summary
    display_config_summary(config)

    console.print()  # Add spacing

    # Display deployment type information
    selector.display_deployment_info(deployment_type)

    console.print()  # Add spacing

    # Get stack file
    stack_file = selector.get_stack_file(deployment_type)
    if stack_file:
        success_panel = Panel.fit(
            f"[bold green]{stack_file}[/bold green]",
            title=" Selected Stack",
            border_style="green",
        )
        console.print(success_panel)
    else:
        console.print(f"[red] No stack file available for {deployment_type}[/red]")
        ctx.exit(1)

    console.print()  # Add spacing

    # Display commands
    selector.export_config(config_file, deployment_type)

    # If export flag is set, also print raw export commands
    if export:
        console.print()
        console.print("[dim]# Copy and paste these commands:[/dim]")
        console.print(f'export TENANT_CONFIG_PATH="{Path(config_file).absolute()}"')
        console.print(f'export SELECTED_STACK="{stack_file}"')
        console.print(f'export DEPLOYMENT_TYPE="{deployment_type}"')

    console.print()  # Add spacing
