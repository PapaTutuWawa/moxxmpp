import sys
import subprocess
import urllib
import yaml
import requests

def main():
    if len(sys.argv) != 3:
        print('Usage: pubspec2lock.py <input> <output>')
        exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
        
    with open(input_file, 'r') as f:
        data = yaml.safe_load(f.read())

    result = {
        'packages': {}
    }
    for package_name in data['packages']:
        print(package_name)
        package = data['packages'][package_name]
        cleaned_url = package["description"]["url"]
        if cleaned_url[-1] == '/':
            cleaned_url = cleaned_url[:-1]

        latest = requests.get(
            f'{cleaned_url}/api/packages/{package_name}',
            headers={
                'Accept': 'application/vnd.pub.v2+json',
            },
        )

        latest_data = None
        try:
            latest_data = latest.json()
        except:
            print(latest.text)
            exit(1)

        for version_data in latest_data['versions']:
            if version_data['version'] == package['version']:
                package['archive_url'] = version_data['archive_url']

                p = subprocess.run([
                    'nix-prefetch-url',
                    '--unpack',
                    urllib.parse.unquote(version_data['archive_url']),
                ], capture_output=True)
                sha256 = p.stdout.decode('utf8')[:-1]
                    
                package['sha256'] = sha256
                break

        result['packages'][package_name] = package

    with open(output_file, 'w') as f:
        f.write('# CREATED BY pubspec2lock.py\n')
        f.write('# DO NOT EDIT BY HAND\n')
        f.write(yaml.dump(result))

if __name__ == '__main__':
    main()
