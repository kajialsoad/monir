import os
import re

# Directory containing test files
test_dir = "G:\\multispace_cloner1\\multispace_cloner\\testsprite_tests"

# Pattern to find window.innerHeight
pattern = r'window\.innerHeight'
replacement = '500'

# Get all Python test files
test_files = [f for f in os.listdir(test_dir) if f.startswith('TC') and f.endswith('.py')]

print(f"Found {len(test_files)} test files to fix:")
for file in test_files:
    print(f"  - {file}")

# Fix each file
fixed_count = 0
for filename in test_files:
    filepath = os.path.join(test_dir, filename)
    
    try:
        # Read file content
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Check if file contains the error
        if 'window.innerHeight' in content:
            # Replace window.innerHeight with 500
            new_content = re.sub(pattern, replacement, content)
            
            # Write back to file
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            
            print(f"Fixed: {filename}")
            fixed_count += 1
        else:
            print(f"No issues found in: {filename}")
            
    except Exception as e:
        print(f"Error processing {filename}: {e}")

print(f"\nFixed {fixed_count} files successfully!")