#!/usr/bin/env python3
"""
Stack selector based on deployment type.
Loads deployment type configurations from YAML files for maintainability.
"""

import sys
import os
import yaml
from pathlib import Path
from typing import Dict, Optional, Tuple, List
import glob

# Color codes for terminal output
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    END = '\033[0m'

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
            print(f"{Colors.RED}❌ Error: Deployment configs directory not found: {self.config_dir}{Colors.END}")
            sys.exit(1)
        
        # Find all YAML config files
        config_files = list(self.config_dir.glob("*.yaml")) + list(self.config_dir.glob("*.yml"))
        
        if not config_files:
            print(f"{Colors.RED}❌ Error: No deployment configuration files found in {self.config_dir}{Colors.END}")
            sys.exit(1)
        
        # Load each config file
        for config_file in config_files:
            try:
                with open(config_file, 'r') as f:
                    config = yaml.safe_load(f)
                    if config and 'name' in config:
                        # Skip disabled configurations
                        if config.get('enabled', True):
                            self.deployment_stacks[config['name']] = config
                        else:
                            print(f"{Colors.YELLOW}⚠️  Skipping disabled config: {config['name']}{Colors.END}")
            except yaml.YAMLError as e:
                print(f"{Colors.YELLOW}⚠️  Warning: Failed to load {config_file}: {e}{Colors.END}")
            except Exception as e:
                print(f"{Colors.YELLOW}⚠️  Warning: Error loading {config_file}: {e}{Colors.END}")
        
        if not self.deployment_stacks:
            print(f"{Colors.RED}❌ Error: No valid deployment configurations loaded{Colors.END}")
            sys.exit(1)
        
        print(f"{Colors.GREEN}✓ Loaded {len(self.deployment_stacks)} deployment configurations{Colors.END}")
    
    def get_deployment_type(self, config: Dict) -> str:
        """Extract deployment type from configuration."""
        deployment_type = config.get('deployment_type')
        
        if not deployment_type:
            print(f"{Colors.YELLOW}⚠️  Warning: deployment_type not specified in configuration{Colors.END}")
            print(f"   Defaulting to 'full_stack'")
            return 'full_stack'
        
        if deployment_type not in self.deployment_stacks:
            print(f"{Colors.RED}❌ Error: Unknown deployment type: {deployment_type}{Colors.END}")
            print(f"   Valid types: {', '.join(sorted(self.deployment_stacks.keys()))}")
            sys.exit(1)
        
        return deployment_type
    
    def display_deployment_info(self, deployment_type: str):
        """Display information about the selected deployment type."""
        info = self.deployment_stacks[deployment_type]
        
        print(f"\n{Colors.BOLD}🚀 Deployment Type: {deployment_type}{Colors.END}")
        print(f"{Colors.CYAN}{'='*50}{Colors.END}")
        print(f"Description: {info.get('description', 'N/A')}")
        
        # Display components
        if 'components' in info:
            print(f"\n{Colors.BOLD}Components:{Colors.END}")
            for component in info['components']:
                print(f"  ✓ {component}")
        
        # Display features
        if 'features' in info:
            print(f"\n{Colors.BOLD}Enabled Features:{Colors.END}")
            features = info['features']
            for i in range(0, len(features), 3):
                feature_row = features[i:i+3]
                print("  " + "  ".join(f"• {f}" for f in feature_row))
        
        # Display disabled features
        if 'disabled_features' in info:
            print(f"\n{Colors.BOLD}Disabled Features:{Colors.END}")
            disabled = info['disabled_features']
            for i in range(0, len(disabled), 3):
                feature_row = disabled[i:i+3]
                print("  " + "  ".join(f"✗ {f}" for f in feature_row))
        
        # Display cluster config
        if 'cluster_config' in info:
            cluster = info['cluster_config']
            print(f"\n{Colors.BOLD}Cluster Configuration:{Colors.END}")
            print(f"  Node Types: {', '.join(cluster.get('node_instance_types', []))}")
            print(f"  Node Count: {cluster.get('min_nodes', 'N/A')}-{cluster.get('max_nodes', 'N/A')} (desired: {cluster.get('desired_nodes', 'N/A')})")
            if cluster.get('spot_enabled'):
                print(f"  Spot Usage: {cluster.get('spot_percentage', 0)}%")
        
        # Display subnet config
        if 'subnet_config' in info:
            subnet = info['subnet_config']
            print(f"\n{Colors.BOLD}Network Configuration:{Colors.END}")
            print(f"  Availability Zones: {subnet.get('count', 'N/A')}")
            print(f"  NAT Strategy: {subnet.get('nat_strategy', 'N/A')}")
            
        # Display special configurations
        if 'security' in info:
            print(f"\n{Colors.BOLD}Security:{Colors.END}")
            security = info['security']
            print(f"  Encryption: {security.get('encryption', 'N/A')}")
            if 'compliance' in security:
                print(f"  Compliance: {', '.join(security['compliance'])}")
        
        if 'hybrid_config' in info:
            print(f"\n{Colors.BOLD}Hybrid Configuration:{Colors.END}")
            hybrid = info['hybrid_config']
            print(f"  Control Plane: {hybrid.get('control_plane_endpoint', 'N/A')}")
            print(f"  Telemetry Forward: {hybrid.get('telemetry_forward', False)}")
    
    def get_stack_file(self, deployment_type: str) -> Optional[str]:
        """Get the stack file path for the deployment type."""
        stack_info = self.deployment_stacks[deployment_type]
        stack_file = stack_info.get('stack_file')
        
        if not stack_file:
            print(f"{Colors.RED}❌ Error: Stack file not configured for {deployment_type}{Colors.END}")
            if not stack_info.get('enabled', True):
                print(f"   This deployment type is not yet implemented")
            return None
        
        # Check if stack file exists
        stack_path = self.script_dir / stack_file
        
        if not stack_path.exists():
            print(f"{Colors.YELLOW}⚠️  Warning: Stack file not found: {stack_file}{Colors.END}")
            print(f"   Expected at: {stack_path}")
            return stack_file  # Return anyway for use in commands
        
        return stack_file
    
    def list_available_types(self):
        """List all available deployment types."""
        print(f"\n{Colors.BOLD}Available Deployment Types:{Colors.END}")
        print(f"{Colors.CYAN}{'='*60}{Colors.END}")
        
        # Sort by name for consistent output
        for dtype in sorted(self.deployment_stacks.keys()):
            info = self.deployment_stacks[dtype]
            stack_file = info.get('stack_file')
            status = "✓" if stack_file else "⏳"
            desc = info.get('description', 'No description')
            
            print(f"{status} {Colors.BOLD}{dtype:15}{Colors.END} - {desc}")
            
            # Show key features inline
            if 'features' in info:
                features = info['features'][:3]  # Show first 3 features
                if features:
                    feature_str = ', '.join(features)
                    if len(info['features']) > 3:
                        feature_str += f" (+{len(info['features'])-3} more)"
                    print(f"  └─ Features: {feature_str}")
    
    def export_config(self, config_file: str, deployment_type: str):
        """Display export commands for automation."""
        config_path = Path(config_file).absolute()
        stack_info = self.deployment_stacks[deployment_type]
        stack_file = stack_info.get('stack_file', '')
        
        print(f"\n{Colors.BOLD}📦 Deployment Commands{Colors.END}")
        print(f"{Colors.CYAN}{'='*50}{Colors.END}")
        
        print(f"\n{Colors.BOLD}1. Set environment:{Colors.END}")
        print(f"   {Colors.GREEN}export TENANT_CONFIG_PATH=\"{config_path}\"{Colors.END}")
        
        if stack_file:
            print(f"\n{Colors.BOLD}2. Initialize stack:{Colors.END}")
            print(f"   {Colors.GREEN}terragrunt stack init --stack {stack_file}{Colors.END}")
            
            print(f"\n{Colors.BOLD}3. Plan deployment:{Colors.END}")
            print(f"   {Colors.GREEN}terragrunt stack plan --stack {stack_file}{Colors.END}")
            
            print(f"\n{Colors.BOLD}4. Apply deployment:{Colors.END}")
            print(f"   {Colors.GREEN}terragrunt stack apply --stack {stack_file}{Colors.END}")
        
        print(f"\n{Colors.BOLD}For automation, export:{Colors.END}")
        print(f"   {Colors.BLUE}export SELECTED_STACK=\"{stack_file}\"{Colors.END}")
        print(f"   {Colors.BLUE}export DEPLOYMENT_TYPE=\"{deployment_type}\"{Colors.END}")
        
        # Export additional configuration that might be useful
        if 'cluster_config' in stack_info:
            cluster = stack_info['cluster_config']
            print(f"   {Colors.BLUE}export NODE_MIN={cluster.get('min_nodes', 1)}{Colors.END}")
            print(f"   {Colors.BLUE}export NODE_MAX={cluster.get('max_nodes', 10)}{Colors.END}")

def display_config_summary(config: Dict):
    """Display summary of the configuration."""
    print(f"\n{Colors.BOLD}📋 Configuration Summary{Colors.END}")
    print(f"{Colors.CYAN}{'='*50}{Colors.END}")
    
    # Core settings
    print(f"Organization:    {config.get('org', 'N/A')}")
    print(f"Environment:     {config.get('env', 'N/A')}")
    print(f"Region:          {config.get('region', 'N/A')} ({config.get('sregion', 'N/A')})")
    print(f"Deployment:      {config.get('deployment', 'N/A')}")
    print(f"Account ID:      {config.get('account_id', 'N/A')}")
    print(f"Deployment Type: {Colors.GREEN}{config.get('deployment_type', 'full_stack')}{Colors.END}")
    
    # Optional settings
    if 'vpc_cidr' in config:
        print(f"VPC CIDR:        {config['vpc_cidr']}")
    if 'domain_name' in config:
        print(f"Domain:          {config['domain_name']}")

def load_config(config_file: str) -> Dict:
    """Load and parse YAML configuration file."""
    try:
        with open(config_file, 'r') as f:
            config = yaml.safe_load(f)
            if not config:
                raise ValueError("Empty configuration file")
            return config
    except FileNotFoundError:
        print(f"{Colors.RED}❌ Error: Configuration file not found: {config_file}{Colors.END}")
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"{Colors.RED}❌ Error: Invalid YAML in configuration file:{Colors.END}")
        print(f"  {e}")
        sys.exit(1)
    except Exception as e:
        print(f"{Colors.RED}❌ Error loading configuration: {e}{Colors.END}")
        sys.exit(1)

def validate_config(config: Dict) -> Tuple[bool, List[str]]:
    """Validate the configuration has required fields."""
    required_fields = ['org', 'env', 'region', 'deployment', 'account_id']
    missing_fields = []
    
    for field in required_fields:
        if field not in config or not config[field]:
            missing_fields.append(field)
    
    if missing_fields:
        return False, missing_fields
    return True, []

def main():
    """Main function."""
    # Initialize stack selector
    selector = StackSelector()
    
    # Parse arguments
    if len(sys.argv) < 2:
        print(f"{Colors.BOLD}Stack Selector - Choose the right Terragrunt stack based on deployment type{Colors.END}")
        print(f"\nUsage: {sys.argv[0]} <config.yaml>")
        print(f"       {sys.argv[0]} --list")
        print(f"\nExample: {sys.argv[0]} configs/test-usw2-app03.yaml")
        selector.list_available_types()
        print(f"\n{Colors.CYAN}Configuration files loaded from: {selector.config_dir}{Colors.END}")
        sys.exit(0)
    
    if sys.argv[1] in ['-h', '--help']:
        print(f"{Colors.BOLD}Stack Selector - Choose the right Terragrunt stack based on deployment type{Colors.END}")
        print(f"\nUsage: {sys.argv[0]} <config.yaml>")
        print(f"       {sys.argv[0]} --list")
        print(f"\nOptions:")
        print(f"  -h, --help   Show this help message")
        print(f"  --list       List all available deployment types")
        print(f"\nExample: {sys.argv[0]} configs/test-usw2-app03.yaml")
        print(f"\n{Colors.CYAN}Configuration files loaded from: {selector.config_dir}{Colors.END}")
        sys.exit(0)
    
    if sys.argv[1] == '--list':
        selector.list_available_types()
        print(f"\n{Colors.CYAN}Configuration files loaded from: {selector.config_dir}{Colors.END}")
        print(f"\n💡 {Colors.GREEN}To add or modify deployment types, edit files in:{Colors.END}")
        print(f"   {selector.config_dir}")
        sys.exit(0)
    
    config_file = sys.argv[1]
    
    # Check if file exists
    if not Path(config_file).exists():
        print(f"{Colors.RED}❌ Error: Configuration file not found: {config_file}{Colors.END}")
        sys.exit(1)
    
    # Load configuration
    print(f"{Colors.BOLD}🔍 Loading configuration: {config_file}{Colors.END}")
    config = load_config(config_file)
    
    # Validate configuration
    valid, missing = validate_config(config)
    if not valid:
        print(f"{Colors.RED}❌ Error: Missing required fields in configuration:{Colors.END}")
        for field in missing:
            print(f"   • {field}")
        sys.exit(1)
    
    # Get deployment type
    deployment_type = selector.get_deployment_type(config)
    
    # Display configuration summary
    display_config_summary(config)
    
    # Display deployment type information
    selector.display_deployment_info(deployment_type)
    
    # Get stack file
    stack_file = selector.get_stack_file(deployment_type)
    if stack_file:
        print(f"\n{Colors.BOLD}✅ Selected stack: {Colors.GREEN}{stack_file}{Colors.END}")
    else:
        print(f"\n{Colors.RED}❌ No stack file available for {deployment_type}{Colors.END}")
        sys.exit(1)
    
    # Display commands
    selector.export_config(config_file, deployment_type)
    
    print(f"\n{Colors.GREEN}✨ Ready to deploy!{Colors.END}")

if __name__ == '__main__':
    main()