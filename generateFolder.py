import os
import sys
import subprocess

def run_gnetgen_on_all(input_dir, output_dir, gnetgen_path="./genInstance.sh"):
   for root, dirs, files in os.walk(input_dir):
      for file in files:
         input_path = os.path.join(root, file)
         rel_path = os.path.relpath(root, input_dir)
         output_subdir = os.path.join(output_dir, rel_path)
         os.makedirs(output_subdir, exist_ok=True)

         output_filename = file + ".txt"
         output_path = os.path.join(output_subdir, output_filename)

         if os.path.exists(output_path):
            print(f"⏭️  Skipping (already exists): {output_path}")
            continue

         try:
            subprocess.run(
                  [gnetgen_path, input_path, output_path],
                  check=True,
                  stdout=subprocess.DEVNULL,
                  stderr=subprocess.DEVNULL
            )
            print(f"✅ Generated: {output_path}")
         except subprocess.CalledProcessError:
            print(f"❌ Error generating: {output_path}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python generateFolder.py <input_dir> <output_dir> [gnetgen_path]")
        sys.exit(1)

    input_dir = sys.argv[1]
    output_dir = sys.argv[2]
    gnetgen_path = sys.argv[3] if len(sys.argv) > 3 else "./genInstance.sh"

    run_gnetgen_on_all(input_dir, output_dir, gnetgen_path)
