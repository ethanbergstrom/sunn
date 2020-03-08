import boto3
import json
import datetime
import time

from gpiozero import CPUTemperature
from envirophat import weather, light, motion, leds

def invoke_lambda(lux, rgb, accelerometer, heading, temperature, pressure):
    client = boto3.client('lambda')
    payload = {
        # Python's datetime library violates ISO 8601, so we need to add "Z" at the end to indicate GMT+0
        'collectedAt': datetime.datetime.utcnow().isoformat() + 'Z',
        'lux': lux,
        'rgb': rgb,
        'accelerometer': accelerometer,
        'heading': heading,
        'temperature': temperature,
        'pressure': pressure
    }

    client.invoke(
        FunctionName = 'caerusEnviroStore',
        Payload = json.dumps(payload)
    )

if __name__ == '__main__':

    temp_calibrate_factor = 2.0

    try:
        lux = light.light()
        leds.on()
        rgb = str(light.rgb())[1:-1].replace(' ', '')
        leds.off()
        accelerometer = str(motion.accelerometer())[1:-1].replace(' ', '')
        heading = motion.heading()
        temperature = weather.temperature()
        # Calibrate ambient temperature by adjusting for CPU heat
        # https://medium.com/initial-state/tutorial-review-enviro-phat-for-raspberry-pi-4cd6d8c63441
        temperature_calibrated = temperature - ((CPUTemperature().temperature - temperature) / temp_calibrate_factor)
        pressure = weather.pressure()
        invoke_lambda(lux, rgb, accelerometer, heading, temperature_calibrated, pressure)

    except KeyboardInterrupt:
        leds.off()
