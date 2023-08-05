#!/usr/bin/env python3
import boto3
import json
import datetime
from ltr559 import LTR559
from bme280 import BME280
from gpiozero import CPUTemperature
try:
    from smbus2 import SMBus
except ImportError:
    from smbus import SMBus

# The LTR559 captures light levels
ltr559 = LTR559()

# The BME280 captures temperature, pressure, and humidity
# Must be set up in 'forced' mode to discard the initial junk readings
bme280 = BME280(i2c_dev=SMBus(1))
bme280.setup(mode="forced")

# Calibrate ambient temperature by adjusting for CPU heat
# https://medium.com/initial-state/tutorial-review-enviro-phat-for-raspberry-pi-4cd6d8c63441
temperature_raw = bme280.get_temperature()
temperature_calibrated = temperature_raw - ((CPUTemperature().temperature - temperature_raw) / 2.5)

payload = {
    # Python's datetime library violates ISO 8601, so we need to add "Z" at the end to indicate GMT+0
    'collectedAt': datetime.datetime.utcnow().isoformat() + 'Z',
    'lux': ltr559.get_lux(),
    'temperature': temperature_calibrated,
    'pressure': bme280.get_pressure()
}

client = boto3.client('lambda')
client.invoke(
    FunctionName = 'caerusEnviroStore',
    Payload = json.dumps(payload)
)
