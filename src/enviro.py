import boto3
import json
import datetime
import time

from envirophat import weather, light, motion, leds

def invoke_lambda(lux, rgb, accelerometer, temperature, pressure):
    client = boto3.client('lambda')
    payload = {
        'collectDateTime': datetime.datetime.utcnow().isoformat(),
        'lux': lux,
        'rgb': rgb,
        'accelerometer': accelerometer,
        'temperature': temperature,
        'pressure': pressure
    }

    client.invoke(
        FunctionName = 'enviroPut',
        Payload = json.dumps(payload)
    )

if __name__ == '__main__':

    try:
        while True:
            lux = light.light()
            leds.on()
            rgb = str(light.rgb())[1:-1].replace(' ', '')
            leds.off()
            accelerometer = str(motion.accelerometer())[1:-1].replace(' ', '')
            heading = motion.heading()
            temperature = weather.temperature()
            pressure = weather.pressure()
            invoke_lambda(lux, rgb, accelerometer, temperature, pressure)
            time.sleep(300)

    except KeyboardInterrupt:
        leds.off()
