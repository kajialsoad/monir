import os
import subprocess
import json
import time
from datetime import datetime

# Test directory
test_dir = "G:\\multispace_cloner1\\multispace_cloner\\testsprite_tests"

# Get all test files
test_files = [f for f in os.listdir(test_dir) if f.startswith('TC') and f.endswith('.py')]
test_files.sort()

print(f"Found {len(test_files)} test cases to execute:")
for i, file in enumerate(test_files, 1):
    print(f"  {i:2d}. {file}")

print("\n" + "="*80)
print("STARTING TESTSPRITE MCP BACKEND TEST EXECUTION")
print("="*80)

# Test results storage
test_results = {
    "execution_time": datetime.now().isoformat(),
    "total_tests": len(test_files),
    "passed": 0,
    "failed": 0,
    "results": []
}

# Execute each test
for i, test_file in enumerate(test_files, 1):
    print(f"\n[{i}/{len(test_files)}] Executing: {test_file}")
    print("-" * 60)
    
    start_time = time.time()
    
    try:
        # Run the test
        result = subprocess.run(
            ["python", test_file],
            cwd=test_dir,
            capture_output=True,
            text=True,
            timeout=60  # 60 second timeout per test
        )
        
        execution_time = time.time() - start_time
        
        # Analyze result
        if result.returncode == 0:
            status = "PASSED"
            test_results["passed"] += 1
            print(f"✅ PASSED ({execution_time:.2f}s)")
        else:
            status = "FAILED"
            test_results["failed"] += 1
            print(f"❌ FAILED ({execution_time:.2f}s)")
            
            # Extract error info
            if "AssertionError" in result.stderr:
                error_type = "Assertion Failure"
            elif "TimeoutError" in result.stderr:
                error_type = "Timeout Error"
            elif "NameError" in result.stderr:
                error_type = "Name Error"
            else:
                error_type = "Runtime Error"
                
            print(f"   Error Type: {error_type}")
            
            # Show last few lines of error
            error_lines = result.stderr.strip().split('\n')
            if error_lines:
                print(f"   Error: {error_lines[-1]}")
        
        # Store result
        test_results["results"].append({
            "test_file": test_file,
            "status": status,
            "execution_time": execution_time,
            "return_code": result.returncode,
            "stdout": result.stdout[:500] if result.stdout else "",
            "stderr": result.stderr[:500] if result.stderr else ""
        })
        
    except subprocess.TimeoutExpired:
        execution_time = time.time() - start_time
        status = "TIMEOUT"
        test_results["failed"] += 1
        print(f"⏰ TIMEOUT ({execution_time:.2f}s)")
        
        test_results["results"].append({
            "test_file": test_file,
            "status": status,
            "execution_time": execution_time,
            "return_code": -1,
            "stdout": "",
            "stderr": "Test execution timed out after 60 seconds"
        })
        
    except Exception as e:
        execution_time = time.time() - start_time
        status = "ERROR"
        test_results["failed"] += 1
        print(f"💥 ERROR ({execution_time:.2f}s): {str(e)}")
        
        test_results["results"].append({
            "test_file": test_file,
            "status": status,
            "execution_time": execution_time,
            "return_code": -2,
            "stdout": "",
            "stderr": str(e)
        })

print("\n" + "="*80)
print("TESTSPRITE MCP BACKEND TEST EXECUTION COMPLETED")
print("="*80)

# Summary
print(f"\nTEST SUMMARY:")
print(f"  Total Tests: {test_results['total_tests']}")
print(f"  Passed: {test_results['passed']} ✅")
print(f"  Failed: {test_results['failed']} ❌")
print(f"  Success Rate: {(test_results['passed']/test_results['total_tests']*100):.1f}%")

# Save detailed results
results_file = os.path.join(test_dir, "testsprite_backend_results.json")
with open(results_file, 'w', encoding='utf-8') as f:
    json.dump(test_results, f, indent=2, ensure_ascii=False)

print(f"\nDetailed results saved to: {results_file}")

# Generate summary report
report_file = os.path.join(test_dir, "testsprite_backend_report.md")
with open(report_file, 'w', encoding='utf-8') as f:
    f.write("# TestSprite MCP Backend Test Execution Report\n\n")
    f.write(f"**Execution Time:** {test_results['execution_time']}\n\n")
    f.write(f"**Summary:**\n")
    f.write(f"- Total Tests: {test_results['total_tests']}\n")
    f.write(f"- Passed: {test_results['passed']} ✅\n")
    f.write(f"- Failed: {test_results['failed']} ❌\n")
    f.write(f"- Success Rate: {(test_results['passed']/test_results['total_tests']*100):.1f}%\n\n")
    
    f.write("## Test Results\n\n")
    for result in test_results['results']:
        status_icon = "✅" if result['status'] == "PASSED" else "❌"
        f.write(f"### {result['test_file']} {status_icon}\n")
        f.write(f"- **Status:** {result['status']}\n")
        f.write(f"- **Execution Time:** {result['execution_time']:.2f}s\n")
        f.write(f"- **Return Code:** {result['return_code']}\n")
        if result['stderr']:
            f.write(f"- **Error:** {result['stderr'][:200]}...\n")
        f.write("\n")

print(f"Summary report saved to: {report_file}")
print("\nTestSprite MCP Backend Testing Complete! 🎯")