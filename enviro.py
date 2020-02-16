import boto3
import json
import datetime
import time

from subprocess import PIPE, Popen
from envirophat import weather, light, motion, leds

def get_cpu_temperature():
    process = Popen(['vcgencmd', 'measure_temp'], stdout=PIPE)
    output, _error = process.communicate()
    return float(output[output.index('=') + 1:output.rindex("'")])

def invoke_lambda(lux, rgb, accelerometer, heading, temperature, pressure):
    client = boto3.client('lambda')
    payload = {
        'collectedAt': datetime.datetime.utcnow().isoformat(),
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

    temp_calibrate_factor = 1.3

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
        temperature_calibrated = temperature - ((get_cpu_temperature() - temperature) / temp_calibrate_factor)
        pressure = weather.pressure()
        invoke_lambda(lux, rgb, accelerometer, heading, temperature_calibrated, pressure)

    except KeyboardInterrupt:
        leds.off()
