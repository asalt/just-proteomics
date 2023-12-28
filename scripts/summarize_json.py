import sys
import json

def summarize(data, list_limit=10, key_limit=12):
    "Recursively reduce data to just the first X nested keys and list items"
    if not isinstance(data, (list, dict)):
        return data
    if isinstance(data, list):
        return [summarize(item, list_limit, key_limit) for item in data[:list_limit]]
    if isinstance(data, dict):
        all_keys = list(data.keys())
        kept_keys = all_keys[:key_limit]
        truncated_keys = all_keys[key_limit:]
        d = dict([
            (key, summarize(data[key], list_limit, key_limit))
            for key in kept_keys
        ])
        if truncated_keys:
            d["_truncated_keys"] = truncated_keys
        return d

f = sys.argv[-1]
with open(f) as open_f:
    json_dict = json.load(open_f)
print(
summarize(json_dict)
)


