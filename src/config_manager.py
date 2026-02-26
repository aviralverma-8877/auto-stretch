"""
Configuration Manager for Auto Stretch

Provides unified configuration management with JSON file as primary source
and Windows Registry as fallback/metadata storage.

This eliminates the configuration drift issues from the old implementation
where config was scattered across .env files, PowerShell variables, NSIS vars, etc.
"""

import json
import os
import sys

# Windows registry support (graceful degradation if not available)
try:
    import winreg
    REGISTRY_AVAILABLE = True
except ImportError:
    REGISTRY_AVAILABLE = False
    print("Warning: winreg not available. Registry operations will be skipped.")


class ConfigManager:
    """Unified configuration management for Auto Stretch"""

    # Default paths (adjusted based on installation location)
    DEFAULT_CONFIG_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "config.json")
    REGISTRY_KEY = r"SOFTWARE\AutoStretch"
    REGISTRY_ROOT = winreg.HKEY_LOCAL_MACHINE if REGISTRY_AVAILABLE else None

    # Default configuration values
    DEFAULT_CONFIG = {
        'version': '2.0.0',
        'port': 5000,
        'debug': False,
        'max_upload_mb': 500,
        'log_level': 'INFO',
        'temp_dir': None,  # Will use system temp if not specified
        'paths': {
            'base': None,  # Will be auto-detected
            'app': None,
            'python': None,
            'logs': None
        }
    }

    @classmethod
    def load_config(cls, config_path=None):
        """
        Load configuration from JSON file with registry fallback

        Args:
            config_path: Path to config file (default: DEFAULT_CONFIG_PATH)

        Returns:
            dict: Configuration dictionary
        """
        config_path = config_path or cls.DEFAULT_CONFIG_PATH
        config = cls.DEFAULT_CONFIG.copy()

        # Try to load from JSON file
        if os.path.exists(config_path):
            try:
                with open(config_path, 'r') as f:
                    file_config = json.load(f)
                    config.update(file_config)
                    return config
            except Exception as e:
                print(f"Warning: Failed to load config from {config_path}: {e}")

        # Fallback to registry if file doesn't exist or failed to load
        if REGISTRY_AVAILABLE:
            try:
                registry_config = cls._load_from_registry()
                if registry_config:
                    config.update(registry_config)
                    print(f"Configuration loaded from registry")
                    return config
            except Exception as e:
                print(f"Warning: Failed to load config from registry: {e}")

        print("Using default configuration")
        return config

    @classmethod
    def save_config(cls, config, config_path=None):
        """
        Save configuration to JSON file and registry

        Args:
            config: Configuration dictionary to save
            config_path: Path to config file (default: DEFAULT_CONFIG_PATH)

        Returns:
            bool: True if successful, False otherwise
        """
        config_path = config_path or cls.DEFAULT_CONFIG_PATH

        # Save to JSON file
        try:
            # Ensure directory exists
            os.makedirs(os.path.dirname(config_path), exist_ok=True)

            with open(config_path, 'w') as f:
                json.dump(config, f, indent=2)
            print(f"Configuration saved to {config_path}")

            # Also save key values to registry
            if REGISTRY_AVAILABLE:
                cls._save_to_registry(config)

            return True

        except Exception as e:
            print(f"Error: Failed to save config to {config_path}: {e}")
            return False

    @classmethod
    def get(cls, key, default=None, config_path=None):
        """
        Get a specific configuration value

        Args:
            key: Configuration key (supports dot notation for nested keys)
            default: Default value if key not found
            config_path: Path to config file (default: DEFAULT_CONFIG_PATH)

        Returns:
            Configuration value or default
        """
        config = cls.load_config(config_path)

        # Support dot notation for nested keys (e.g., "paths.base")
        keys = key.split('.')
        value = config

        for k in keys:
            if isinstance(value, dict) and k in value:
                value = value[k]
            else:
                return default

        return value

    @classmethod
    def set(cls, key, value, config_path=None):
        """
        Set a specific configuration value

        Args:
            key: Configuration key (supports dot notation for nested keys)
            value: Value to set
            config_path: Path to config file (default: DEFAULT_CONFIG_PATH)

        Returns:
            bool: True if successful, False otherwise
        """
        config = cls.load_config(config_path)

        # Support dot notation for nested keys
        keys = key.split('.')
        target = config

        for k in keys[:-1]:
            if k not in target or not isinstance(target[k], dict):
                target[k] = {}
            target = target[k]

        target[keys[-1]] = value

        return cls.save_config(config, config_path)

    @classmethod
    def _load_from_registry(cls):
        """Load configuration from Windows Registry"""
        if not REGISTRY_AVAILABLE:
            return {}

        config = {}
        try:
            with winreg.OpenKey(cls.REGISTRY_ROOT, cls.REGISTRY_KEY) as key:
                # Read port
                try:
                    port, _ = winreg.QueryValueEx(key, 'Port')
                    config['port'] = int(port)
                except WindowsError:
                    pass

                # Read version
                try:
                    version, _ = winreg.QueryValueEx(key, 'Version')
                    config['version'] = version
                except WindowsError:
                    pass

                # Read install path
                try:
                    install_path, _ = winreg.QueryValueEx(key, 'InstallPath')
                    if 'paths' not in config:
                        config['paths'] = {}
                    config['paths']['base'] = install_path
                except WindowsError:
                    pass

        except WindowsError:
            # Registry key doesn't exist
            pass

        return config

    @classmethod
    def _save_to_registry(cls, config):
        """Save key configuration values to Windows Registry"""
        if not REGISTRY_AVAILABLE:
            return

        try:
            # Create or open registry key
            key = winreg.CreateKey(cls.REGISTRY_ROOT, cls.REGISTRY_KEY)

            # Save port
            if 'port' in config:
                winreg.SetValueEx(key, 'Port', 0, winreg.REG_DWORD, int(config['port']))

            # Save version
            if 'version' in config:
                winreg.SetValueEx(key, 'Version', 0, winreg.REG_SZ, str(config['version']))

            # Save install path
            if 'paths' in config and 'base' in config['paths'] and config['paths']['base']:
                winreg.SetValueEx(key, 'InstallPath', 0, winreg.REG_SZ, config['paths']['base'])

            winreg.CloseKey(key)
            print("Configuration saved to registry")

        except Exception as e:
            print(f"Warning: Failed to save to registry: {e}")

    @classmethod
    def validate_config(cls, config):
        """
        Validate configuration

        Args:
            config: Configuration dictionary to validate

        Returns:
            tuple: (is_valid, errors) where errors is a list of error messages
        """
        errors = []

        # Validate port
        if 'port' in config:
            port = config['port']
            if not isinstance(port, int) or port < 1 or port > 65535:
                errors.append(f"Invalid port: {port}. Must be between 1-65535")

        # Validate max_upload_mb
        if 'max_upload_mb' in config:
            max_upload = config['max_upload_mb']
            if not isinstance(max_upload, (int, float)) or max_upload <= 0:
                errors.append(f"Invalid max_upload_mb: {max_upload}. Must be positive number")

        # Validate log_level
        if 'log_level' in config:
            log_level = config['log_level']
            valid_levels = ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL']
            if log_level not in valid_levels:
                errors.append(f"Invalid log_level: {log_level}. Must be one of {valid_levels}")

        return (len(errors) == 0, errors)

    @classmethod
    def create_default_config(cls, config_path=None):
        """
        Create a default configuration file

        Args:
            config_path: Path to config file (default: DEFAULT_CONFIG_PATH)

        Returns:
            bool: True if successful, False otherwise
        """
        config_path = config_path or cls.DEFAULT_CONFIG_PATH

        # Auto-detect base path
        config = cls.DEFAULT_CONFIG.copy()
        base_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        config['paths']['base'] = base_path
        config['paths']['app'] = os.path.join(base_path, 'app')
        config['paths']['python'] = os.path.join(base_path, 'python')
        config['paths']['logs'] = os.path.join(base_path, 'logs')

        return cls.save_config(config, config_path)


# Convenience functions for common operations
def get_port(config_path=None):
    """Get configured port (convenience function)"""
    return ConfigManager.get('port', default=5000, config_path=config_path)


def set_port(port, config_path=None):
    """Set port (convenience function)"""
    return ConfigManager.set('port', port, config_path=config_path)


def get_base_path(config_path=None):
    """Get base installation path (convenience function)"""
    return ConfigManager.get('paths.base', config_path=config_path)


# CLI interface for testing and management
if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Auto Stretch Configuration Manager')
    parser.add_argument('action', choices=['get', 'set', 'show', 'create', 'validate'],
                        help='Action to perform')
    parser.add_argument('--key', help='Configuration key (for get/set)')
    parser.add_argument('--value', help='Configuration value (for set)')
    parser.add_argument('--config', help='Path to config file', default=None)

    args = parser.parse_args()

    if args.action == 'show':
        config = ConfigManager.load_config(args.config)
        print(json.dumps(config, indent=2))

    elif args.action == 'get':
        if not args.key:
            print("Error: --key required for get action")
            sys.exit(1)
        value = ConfigManager.get(args.key, config_path=args.config)
        print(f"{args.key} = {value}")

    elif args.action == 'set':
        if not args.key or not args.value:
            print("Error: --key and --value required for set action")
            sys.exit(1)

        # Try to parse value as JSON (for numbers, booleans, etc.)
        try:
            value = json.loads(args.value)
        except:
            value = args.value

        if ConfigManager.set(args.key, value, config_path=args.config):
            print(f"Set {args.key} = {value}")
        else:
            print(f"Failed to set {args.key}")
            sys.exit(1)

    elif args.action == 'create':
        if ConfigManager.create_default_config(args.config):
            print(f"Created default configuration")
        else:
            print(f"Failed to create configuration")
            sys.exit(1)

    elif args.action == 'validate':
        config = ConfigManager.load_config(args.config)
        is_valid, errors = ConfigManager.validate_config(config)
        if is_valid:
            print("Configuration is valid")
        else:
            print("Configuration has errors:")
            for error in errors:
                print(f"  - {error}")
            sys.exit(1)
