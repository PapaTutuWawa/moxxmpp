'''
This script generates a .nix file containing all dependencies specified in the
special lock file. The .nix file also contains the derivation "pubCache", which can
be used as the path in the PUB_CACHE environment variable.
'''

import sys
import yaml
import urllib.parse

def generate_derivation(package):
    name = package['description']['name']
    sha = package['sha256']
    version = package['version']

    url = ''
    if 'archive_url' in package:
        url = package['archive_url']
    else:
        base_url = package['description']['url']
        url = f'{base_url}/packages/{name}/versions/{version}.tar.gz'

    return f'''
  {name} = fetchzip {{
    sha256 = "{sha}";
    url = "{url}";
    stripRoot = false;
    extension = "tar.gz";
  }};
'''

def main():
    if len(sys.argv) != 4:
        print('Usage: lock2nix.py <input lock> <output nix> <package name>')
        exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    package_name = sys.argv[3]
        
    with open(input_file, 'r') as f:
        data = yaml.safe_load(f.read())

    with open(output_file, 'w') as f:
        f.write('# GENERATED BY LOCK2NIX.py\n')
        f.write('# DO NOT EDIT BY HAND\n')
        f.write('{fetchzip, runCommand} : rec {')
        steps = ''
        for package in data['packages']:
            try:
                f.write(generate_derivation(data['packages'][package]))
            except ex:
                print(f'Failed with {ex} for package {package}')

            print(package)
            source = data['packages'][package]['source']
            prefix = urllib.parse.quote(
                data['packages'][package]['description']['url'][8:],
                safe='',
            ).replace('%2F', '%47')
            name = data['packages'][package]['description']['name']
            version = data['packages'][package]['version']
            steps += f'''
    mkdir -p $out/{source}/{prefix}
    ln -s ${{{package}}} $out/{source}/{prefix}/{name}-{version}
'''
                
        f.write(f'''
  pubCache = runCommand "{package_name}-pub-cache" {{}} ''{steps}'';
''')
        f.write('\n}')

if __name__ == '__main__':
    main()
