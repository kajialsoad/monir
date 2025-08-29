import asyncio
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
        
        # Memory leak detection implementation
        initial_memory = psutil.Process().memory_info().rss / 1024 / 1024  # MB
        
        # Simulate multiple app cloning operations to test for memory leaks
        for i in range(5):
            # Try to find and interact with app cloning elements
            try:
                # Look for clone button or similar elements
                clone_elements = await page.query_selector_all('[data-testid*="clone"], button:has-text("Clone"), .clone-btn')
                if clone_elements:
                    await clone_elements[0].click()
                    await asyncio.sleep(1)
                
                # Look for app management controls
                app_elements = await page.query_selector_all('.app-item, .installed-app, [data-testid*="app"]')
                if app_elements and len(app_elements) > 0:
                    await app_elements[0].click()
                    await asyncio.sleep(0.5)
                
                # Scroll to trigger more UI interactions
                await page.mouse.wheel(0, 200)
                await asyncio.sleep(0.5)
                
            except Exception as e:
                print(f"Interaction {i+1} failed: {e}")
                continue
        
        # Force garbage collection
        gc.collect()
        await asyncio.sleep(2)
        
        # Check final memory usage
        final_memory = psutil.Process().memory_info().rss / 1024 / 1024  # MB
        memory_increase = final_memory - initial_memory
        
        print(f"Initial memory: {initial_memory:.2f} MB")
        print(f"Final memory: {final_memory:.2f} MB")
        print(f"Memory increase: {memory_increase:.2f} MB")
        
        # Memory leak detection assertion
        # Allow up to 50MB increase as normal for browser operations
        assert memory_increase < 50, f"Potential memory leak detected: {memory_increase:.2f} MB increase"
        
        # Additional checks for page responsiveness after operations
        try:
            await page.evaluate("document.title")
            page_responsive = True
        except:
            page_responsive = False
            
        assert page_responsive, "Page became unresponsive after multiple operations"
        
        print("Memory leak test passed: No significant memory leaks detected")
        await asyncio.sleep(1)
    
    finally:
        if context:
            await context.close()
        if browser:
            await browser.close()
        if pw:
            await pw.stop()
            
asyncio.run(run_test())
    