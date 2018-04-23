import boto3
import json
import datetime
import time

from envirophat import weather, light, motion, leds

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
        FunctionName = 'caerus-Enviro-Store',
        Payload = json.dumps(payload)
    )

if __name__ == '__main__':

    try:
        lux = light.light()
        leds.on()
        rgb = str(light.rgb())[1:-1].replace(' ', '')
        leds.off()
        accelerometer = str(motion.accelerometer())[1:-1].replace(' ', '')
        heading = motion.heading()
        temperature = weather.temperature()
        pressure = weather.pressure()
        invoke_lambda(lux, rgb, accelerometer, heading, temperature, pressure)

    except KeyboardInterrupt:
        leds.off()
