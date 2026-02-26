"""
Native Windows Service Wrapper for Auto Stretch

This module implements a Windows service using pywin32 to run the Flask application
as a native Windows service. This eliminates the need for NSSM and all associated
path quoting issues.

Installation:
    python service_wrapper.py install

Start Service:
    python service_wrapper.py start

Stop Service:
    python service_wrapper.py stop

Remove Service:
    python service_wrapper.py remove
"""

import sys
import os
import json
import logging
import socket
from threading import Thread, Event

try:
    import win32serviceutil
    import win32service
    import win32event
    import servicemanager
except ImportError:
    print("ERROR: pywin32 is not installed.")
    print("Please install it with: pip install pywin32")
    sys.exit(1)

# Base directory - will be C:\AutoStretch in production
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_FILE = os.path.join(BASE_DIR, "config.json")
LOG_DIR = os.path.join(BASE_DIR, "logs")
LOG_FILE = os.path.join(LOG_DIR, "service.log")

# Ensure logs directory exists
os.makedirs(LOG_DIR, exist_ok=True)

# Setup logging
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('AutoStretchService')


class AutoStretchService(win32serviceutil.ServiceFramework):
    """
    Native Windows Service for Auto Stretch Flask Application

    This service wrapper provides:
    - Automatic startup on Windows boot
    - Graceful shutdown handling
    - Service recovery options
    - Comprehensive logging
    - Configuration management
    """

    _svc_name_ = "AutoStretch"
    _svc_display_name_ = "Auto Stretch"
    _svc_description_ = "Flask-based web application for processing astronomical TIFF images with advanced stretching algorithms"

    def __init__(self, args):
        """Initialize the service"""
        win32serviceutil.ServiceFramework.__init__(self, args)
        self.stop_event = win32event.CreateEvent(None, 0, 0, None)
        self.is_running = False
        self.flask_thread = None
        logger.info("Service initialized")

    def SvcStop(self):
        """Handle service stop request"""
        logger.info("Service stop requested")
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        self.is_running = False
        win32event.SetEvent(self.stop_event)
        logger.info("Service stopped")

    def SvcDoRun(self):
        """Main service entry point"""
        logger.info("="*60)
        logger.info("Auto Stretch Service Starting")
        logger.info("="*60)

        servicemanager.LogMsg(
            servicemanager.EVENTLOG_INFORMATION_TYPE,
            servicemanager.PYS_SERVICE_STARTED,
            (self._svc_name_, '')
        )

        try:
            self.is_running = True
            self.main()
        except Exception as e:
            logger.error(f"Service failed to start: {e}", exc_info=True)
            servicemanager.LogErrorMsg(f"Auto Stretch Service failed: {str(e)}")
            self.SvcStop()

    def main(self):
        """Main service logic"""
        try:
            # Load configuration
            config = self.load_config()
            port = config.get('port', 5000)
            debug = config.get('debug', False)

            logger.info(f"Configuration loaded: port={port}, debug={debug}")
            logger.info(f"Base directory: {BASE_DIR}")

            # Import Flask app
            sys.path.insert(0, BASE_DIR)

            try:
                from app import app
                logger.info("Flask application imported successfully")
            except ImportError as e:
                logger.error(f"Failed to import Flask app: {e}", exc_info=True)
                raise

            # Check if port is available
            if not self.is_port_available(port):
                logger.error(f"Port {port} is already in use")
                raise Exception(f"Port {port} is already in use. Please change the port in {CONFIG_FILE}")

            # Run Flask in separate thread
            logger.info(f"Starting Flask application on port {port}")

            def run_flask():
                try:
                    app.run(host='0.0.0.0', port=port, debug=debug, threaded=True, use_reloader=False)
                except Exception as e:
                    logger.error(f"Flask application error: {e}", exc_info=True)

            self.flask_thread = Thread(target=run_flask, daemon=True, name="FlaskThread")
            self.flask_thread.start()

            logger.info(f"Service running. Web interface: http://localhost:{port}")
            logger.info("Waiting for stop signal...")

            # Wait for stop signal
            win32event.WaitForSingleObject(self.stop_event, win32event.INFINITE)

            logger.info("Stop signal received. Shutting down...")

        except Exception as e:
            logger.error(f"Service error: {e}", exc_info=True)
            raise

    def load_config(self):
        """Load configuration from JSON file"""
        default_config = {
            'port': 5000,
            'debug': False,
            'max_upload_mb': 500,
            'log_level': 'INFO'
        }

        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, 'r') as f:
                    config = json.load(f)
                    logger.info(f"Configuration loaded from {CONFIG_FILE}")
                    return {**default_config, **config}
            except Exception as e:
                logger.warning(f"Failed to load config file: {e}. Using defaults.")
                return default_config
        else:
            logger.warning(f"Config file not found: {CONFIG_FILE}. Using defaults.")
            # Create default config file
            try:
                with open(CONFIG_FILE, 'w') as f:
                    json.dump(default_config, f, indent=2)
                logger.info(f"Created default config file: {CONFIG_FILE}")
            except Exception as e:
                logger.error(f"Failed to create config file: {e}")
            return default_config

    def is_port_available(self, port):
        """Check if port is available"""
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind(('0.0.0.0', port))
                return True
        except OSError:
            return False


def main():
    """Command-line handler for service installation/management"""
    if len(sys.argv) == 1:
        # Service is being started by Windows Service Manager
        servicemanager.Initialize()
        servicemanager.PrepareToHostSingle(AutoStretchService)
        servicemanager.StartServiceCtrlDispatcher()
    else:
        # Command-line arguments (install, remove, start, stop, etc.)
        win32serviceutil.HandleCommandLine(AutoStretchService)


if __name__ == '__main__':
    main()
