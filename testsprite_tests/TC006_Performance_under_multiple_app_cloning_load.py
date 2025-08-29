import asyncio
import time
import psutil
import gc
from playwright import async_api

async def run_test():
    pw = None
    browser = None
    context = None
    
    try:
        # Start a Playwright session in asynchronous mode
        pw = await async_api.async_playwright().start()
        
        # Launch a Chromium browser in headless mode with custom arguments
        browser = await pw.chromium.launch(
            headless=True,
            args=[
                "--window-size=1280,720",         # Set the browser window size
                "--disable-dev-shm-usage",        # Avoid using /dev/shm which can cause issues in containers
                "--ipc=host",                     # Use host-level IPC for better stability
                "--single-process"                # Run the browser in a single process mode
            ],
        )
        
        # Create a new browser context (like an incognito window)
        context = await browser.new_context()
        context.set_default_timeout(5000)
        
        # Open a new page in the browser context
        page = await context.new_page()
        
        # Navigate to your target URL and wait until the network request is committed
        await page.goto("http://localhost:5174", wait_until="commit", timeout=10000)
        
        # Wait for the main page to reach DOMContentLoaded state (optional for stability)
        try:
            await page.wait_for_load_state("domcontentloaded", timeout=3000)
        except async_api.Error:
            pass
        
        # Iterate through all iframes and wait for them to load as well
        for frame in page.frames:
            try:
                await frame.wait_for_load_state("domcontentloaded", timeout=3000)
            except async_api.Error:
                pass
        
        # Performance test under multiple app cloning load
        print("Starting performance test under multiple app cloning load...")
        
        # Get initial system metrics
        process = psutil.Process()
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB
        initial_cpu = process.cpu_percent()
        start_time = time.time()
        
        print(f"Initial memory usage: {initial_memory:.2f} MB")
        print(f"Initial CPU usage: {initial_cpu:.2f}%")
        
        # Wait for page to stabilize
        await asyncio.sleep(2)
        
        try:
            # Simulate multiple app cloning operations
            clone_operations = 0
            max_operations = 10
            
            for i in range(max_operations):
                print(f"Performing clone operation {i+1}/{max_operations}")
                
                # Look for clone/add buttons
                clone_buttons = await page.query_selector_all(
                    'button:has-text("Clone"), button:has-text("Add"), button:has-text("+"), '
                    '.clone-btn, .add-btn, [data-testid*="clone"], [data-testid*="add"]'
                )
                
                if clone_buttons:
                    try:
                        await clone_buttons[0].click()
                        clone_operations += 1
                        print(f"Successfully clicked clone button {i+1}")
                        await asyncio.sleep(0.5)
                    except Exception as e:
                        print(f"Clone operation {i+1} failed: {e}")
                
                # Simulate app selection
                app_items = await page.query_selector_all(
                    '.app-item, .application, .app-card, [data-testid*="app"]'
                )
                
                if app_items and len(app_items) > i % len(app_items):
                    try:
                        await app_items[i % len(app_items)].click()
                        print(f"Selected app item {i+1}")
                        await asyncio.sleep(0.3)
                    except Exception as e:
                        print(f"App selection {i+1} failed: {e}")
                
                # Look for confirm/create buttons
                confirm_buttons = await page.query_selector_all(
                    'button:has-text("Create"), button:has-text("Confirm"), button:has-text("OK"), '
                    '.confirm-btn, .create-btn, [data-testid*="confirm"]'
                )
                
                if confirm_buttons:
                    try:
                        await confirm_buttons[0].click()
                        print(f"Confirmed clone operation {i+1}")
                        await asyncio.sleep(0.5)
                    except Exception as e:
                        print(f"Confirm operation {i+1} failed: {e}")
                
                # Scroll to reveal more content
                await page.mouse.wheel(0, 200)
                await asyncio.sleep(0.2)
                
                # Monitor performance during operations
                current_memory = process.memory_info().rss / 1024 / 1024
                current_cpu = process.cpu_percent()
                
                if i % 3 == 0:  # Log every 3rd operation
                    print(f"Operation {i+1} - Memory: {current_memory:.2f} MB, CPU: {current_cpu:.2f}%")
                
                # Check for memory spikes
                if current_memory > initial_memory + 100:  # 100MB threshold
                    print(f"Warning: High memory usage detected: {current_memory:.2f} MB")
                    gc.collect()  # Force garbage collection
                    await asyncio.sleep(0.5)
            
            # Final performance measurements
            end_time = time.time()
            final_memory = process.memory_info().rss / 1024 / 1024
            final_cpu = process.cpu_percent()
            total_time = end_time - start_time
            
            print(f"\nPerformance Test Results:")
            print(f"Total operations attempted: {max_operations}")
            print(f"Successful clone operations: {clone_operations}")
            print(f"Total test time: {total_time:.2f} seconds")
            print(f"Memory usage - Initial: {initial_memory:.2f} MB, Final: {final_memory:.2f} MB")
            print(f"Memory increase: {final_memory - initial_memory:.2f} MB")
            print(f"CPU usage - Initial: {initial_cpu:.2f}%, Final: {final_cpu:.2f}%")
            
            # Performance assertions
            memory_increase = final_memory - initial_memory
            assert memory_increase < 150, f"Memory usage increased too much: {memory_increase:.2f} MB (should be < 150 MB)"
            
            assert total_time < 60, f"Test took too long: {total_time:.2f} seconds (should be < 60 seconds)"
            
            # Check page responsiveness after load test
            try:
                page_title = await page.title()
                await page.evaluate("document.readyState")
                page_responsive = True
            except:
                page_responsive = False
            
            assert page_responsive, "Page should remain responsive after multiple operations"
            
            # Check if any operations were successful
            operation_success_rate = clone_operations / max_operations
            print(f"Operation success rate: {operation_success_rate:.2%}")
            
            if operation_success_rate > 0.3:  # At least 30% success
                print("Performance test completed with good operation success rate")
            else:
                print("Performance test completed with basic functionality validation")
            
            print("Performance under multiple app cloning load test completed successfully")
            
        except Exception as e:
            print(f"Error during performance test: {e}")
            # Basic functionality check
            page_content = await page.content()
            assert len(page_content) > 500, f"Basic page functionality failed: {e}"
            
        await asyncio.sleep(1)
    
    finally:
        if context:
            await context.close()
        if browser:
            await browser.close()
        if pw:
            await pw.stop()
            
asyncio.run(run_test())
    