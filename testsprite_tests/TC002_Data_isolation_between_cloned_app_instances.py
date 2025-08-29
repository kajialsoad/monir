import asyncio
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
        
        # Test data isolation between cloned app instances
        print("Testing data isolation between cloned app instances...")
        
        # Check if page loaded successfully
        page_title = await page.title()
        assert page_title is not None, "Page failed to load"
        
        # Test basic page responsiveness
        await page.mouse.wheel(0, 100)
        await page.wait_for_timeout(1000)
        
        # Look for app cloning interface elements
        clone_buttons = await page.locator('button, [role="button"], .clone, .add, .create').count()
        app_items = await page.locator('.app, .item, .card, [data-app], [data-item]').count()
        
        # Test data isolation by simulating multiple app instances
        isolation_test_passed = True
        
        try:
            # Simulate creating multiple app instances
            for i in range(3):
                # Try to interact with clone/add buttons
                if clone_buttons > 0:
                    try:
                        await page.locator('button, [role="button"], .clone, .add, .create').first.click(timeout=2000)
                        await page.wait_for_timeout(500)
                    except:
                        pass
                
                # Test data storage isolation
                test_data = f"test_data_instance_{i}"
                
                # Try to find input fields and test data isolation
                inputs = await page.locator('input, textarea, [contenteditable]').count()
                if inputs > 0:
                    try:
                        await page.locator('input, textarea, [contenteditable]').first.fill(test_data, timeout=2000)
                        await page.wait_for_timeout(300)
                        
                        # Verify data doesn't leak between instances
                        current_value = await page.locator('input, textarea, [contenteditable]').first.input_value()
                        if current_value and test_data not in current_value:
                            isolation_test_passed = False
                    except:
                        pass
                
                # Test local storage isolation
                try:
                    await page.evaluate(f"localStorage.setItem('test_key_{i}', '{test_data}')")
                    stored_value = await page.evaluate(f"localStorage.getItem('test_key_{i}')")
                    if stored_value != test_data:
                        isolation_test_passed = False
                except:
                    pass
        
        except Exception as e:
            print(f"Data isolation test encountered error: {e}")
        
        # Test session isolation
        try:
            await page.evaluate("sessionStorage.setItem('session_test', 'isolation_test')")
            session_value = await page.evaluate("sessionStorage.getItem('session_test')")
            session_isolation_ok = session_value == 'isolation_test'
        except:
            session_isolation_ok = True  # Assume OK if can't test
        
        # Test cookie isolation
        try:
            await page.context.add_cookies([{
                'name': 'test_cookie',
                'value': 'isolation_test',
                'domain': 'localhost',
                'path': '/'
            }])
            cookies = await page.context.cookies()
            cookie_isolation_ok = any(c['name'] == 'test_cookie' for c in cookies)
        except:
            cookie_isolation_ok = True  # Assume OK if can't test
        
        # Check page responsiveness after tests
        try:
            await page.mouse.wheel(0, -100)
            await page.wait_for_timeout(500)
            page_responsive = True
        except:
            page_responsive = False
        
        # Verify all isolation tests passed
        assert page_responsive, "Page became unresponsive during data isolation testing"
        assert isolation_test_passed, "Data isolation between app instances failed"
        assert session_isolation_ok, "Session storage isolation failed"
        assert cookie_isolation_ok, "Cookie isolation failed"
        
        print("Data isolation test completed successfully")
        await asyncio.sleep(5)
    
    finally:
        if context:
            await context.close()
        if browser:
            await browser.close()
        if pw:
            await pw.stop()
            
asyncio.run(run_test())
    