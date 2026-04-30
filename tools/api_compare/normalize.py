import re

TRANSIENT_FIELDS = {
    'id', 'uuid', 'updatedAt', 'createdAt', 'ratingKey', 'key', 'thumb',
    'art', 'parentThumb', 'grandparentThumb', 'updatedAt', 'createdAt',
}


def normalize(obj):
    if isinstance(obj, dict):
        normalized = {}
        for k, v in sorted(obj.items()):
            if k in TRANSIENT_FIELDS:
                continue
            normalized[k] = normalize(v)
        return normalized
    if isinstance(obj, list):
        return sorted((normalize(item) for item in obj), key=lambda x: repr(x))
    if isinstance(obj, str):
        lowered = obj.lower()
        if lowered in {'true', 'false'}:
            return lowered == 'true'
        if re.fullmatch(r'-?\d+', obj):
            return int(obj)
        if re.fullmatch(r'-?\d+\.\d+', obj):
            return float(obj)
        return obj
    return obj
