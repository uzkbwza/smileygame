import os
import subprocess
# print(os.environ['PATH'])


# Get the path of the current script or module
script_path = os.path.abspath(__file__)

# Use os.path.dirname to get the directory containing the script
script_dir = os.path.dirname(script_path)

cmd_template = "\"C:\Program Files\Aseprite\\aseprite.exe\" -b \"{}\" -save-as \"{}-{{tag}}.png\""

def main():
    os.chdir(script_dir)
    for root, dirs, files in os.walk(script_dir):
        if root != script_dir:
            for filename in files:
                if filename.endswith('.aseprite') or filename.endswith('.ase'):
                    process_aseprite_file(root, filename)

def process_aseprite_file(root, filename):
    # Build the full path to the .aseprite file
    file_path = os.path.join(root, filename)
    
    # Extract the filename without extension
    base_name = os.path.splitext(filename)[0]
    
    # Replace <filename> with the actual base name in the command
    cmd = cmd_template.format(file_path, os.path.join(root, base_name))
    
    print(cmd)

    # Run the command using subprocess
    subprocess.run(cmd, shell=True)

if __name__ == "__main__":
    main()