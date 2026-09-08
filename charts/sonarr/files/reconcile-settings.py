"""Reconcile explicitly owned Sonarr settings through its supported API, never SQLite."""
import json
import os
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET

with open('/desired/settings.json', encoding='utf-8') as source:
    desired = json.load(source)
key = ET.parse('/config/config.xml').getroot().findtext('ApiKey')
if not key:
    raise RuntimeError('Sonarr config.xml has no API key')
base = os.environ['SONARR_API_URL'].rstrip('/')


def api(path, data=None, method='GET'):
    request = urllib.request.Request(
        base + '/' + path,
        data=None if data is None else json.dumps(data).encode(),
        headers={'X-Api-Key': key, 'Content-Type': 'application/json'},
        method=method,
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            body = response.read()
            return json.loads(body) if body else None
    except urllib.error.HTTPError as error:
        # Do not log request headers or full provider configuration on failure.
        raise RuntimeError(f'{method} {path} returned HTTP {error.code}') from None


naming = api('config/naming')
if naming['seriesFolderFormat'] != desired['seriesFolderFormat']:
    naming['seriesFolderFormat'] = desired['seriesFolderFormat']
    api('config/naming', naming, 'PUT')
    print('Applied series folder format (existing paths unchanged)', flush=True)
else:
    print('Series folder format already matches', flush=True)

consumers = [x for x in api('metadata') if x['implementation'] == 'XbmcMetadata']
if len(consumers) > 1:
    raise RuntimeError('Multiple Kodi/Emby consumers found; refusing ambiguous update')
existing = bool(consumers)
consumer = consumers[0] if existing else next(
    x for x in api('metadata/schema') if x['implementation'] == 'XbmcMetadata'
)
fields = {field['name']: field for field in consumer['fields']}
missing = set(desired['metadataFields']) - set(fields)
if missing:
    raise RuntimeError('Unsupported metadata fields: ' + ', '.join(sorted(missing)))
changed = not existing or consumer['enable'] is not True
consumer['enable'] = True
if not existing:
    consumer['name'] = 'Kodi (XBMC) / Emby'
for name, value in desired['metadataFields'].items():
    changed |= fields[name].get('value') != value
    fields[name]['value'] = value
if changed:
    api('metadata/' + str(consumer['id']) if existing else 'metadata',
        consumer, 'PUT' if existing else 'POST')
    print('Applied NFO metadata settings', flush=True)
else:
    print('NFO metadata settings already match', flush=True)

# Verify the saved settings rather than treating an accepted request as evidence.
assert api('config/naming')['seriesFolderFormat'] == desired['seriesFolderFormat']
saved = [x for x in api('metadata') if x['implementation'] == 'XbmcMetadata']
assert len(saved) == 1 and saved[0]['enable']
saved_fields = {x['name']: x.get('value') for x in saved[0]['fields']}
assert all(saved_fields[name] == value for name, value in desired['metadataFields'].items())
print('Verified declarative Sonarr settings', flush=True)
