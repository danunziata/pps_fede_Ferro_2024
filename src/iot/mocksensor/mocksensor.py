import time
import json
import random

def generate_random_temperature(sensor_data):
    sensor_data["timestamp"] = time.time()
    current_temp = sensor_data["temperature"]
    difference = random.uniform(0, 0.5)
    add_or_substract = random.randint(0, 1)

    if add_or_substract and current_temp < 35:
        sensor_data["temperature"] += difference
    elif current_temp > 10:
        sensor_data["temperature"] -= difference

def main():
    sensor_data = {
        "device_id": "e2e78334",
        "client_id": "c03d5155",
        "sensor_type": "Temperature",
        "temperature": 25,
        "timestamp": time.time()
    }

    while True:
        generate_random_temperature(sensor_data)
        with open('/tmp/ouput_mock_sensor.json', 'a') as output_file:
            output_file.write(f'{json.dumps(sensor_data)}\n')
        time.sleep(0.5)

if __name__ == '__main__':
    main()