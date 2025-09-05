#!/usr/bin/env python3
import yaml, json

with open("modules.yaml") as f:
    data = yaml.safe_load(f)

# Convertimos la lista de módulos a un string JSON
output = {
    "modules_json": json.dumps(data["modules"])
}

print(json.dumps(output))
