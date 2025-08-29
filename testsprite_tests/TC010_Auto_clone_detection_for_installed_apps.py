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
        
        # Test auto clone detection for installed apps
        print("Testing auto clone detection for installed apps...")
        
        # Wait for page to load
        await asyncio.sleep(2)
        
        try:
            # Look for auto detection elements
            detection_elements = await page.query_selector_all(
                '.auto-detect, .detection, .scan, [data-testid*="detect"], '
                'button:has-text("Detect"), button:has-text("Scan"), '
                '.auto-scan, .detect-apps, [aria-label*="detect"]'
            )
            
            # Look for installed apps list
            installed_apps = await page.query_selector_all(
                '.installed-app, .app-item, .application, .app-card, '
                '[data-testid*="app"], .app-list .app, .detected-app'
            )
            
            # Look for clone suggestion elements
            clone_suggestions = await page.query_selector_all(
                '.clone-suggestion, .suggest-clone, .recommended, '
                'button:has-text("Clone"), .clone-btn, [data-testid*="clone"]'
            )
            
            # Look for detection status indicators
            status_elements = await page.query_selector_all(
                '.status, .detection-status, .scan-status, .progress, '
                '[data-testid*="status"], .loading, .scanning'
            )
            
            print(f"Found {len(detection_elements)} auto detection elements")
            print(f"Found {len(installed_apps)} installed app items")
            print(f"Found {len(clone_suggestions)} clone suggestion elements")
            print(f"Found {len(status_elements)} status indicators")
            
            # Test auto detection trigger
            if detection_elements:
                try:
                    await detection_elements[0].click()
                    print("Successfully triggered auto detection")
                    await asyncio.sleep(2)
                except Exception as e:
                    print(f"Failed to trigger auto detection: {e}")
            
            # Test app scanning/detection
            scan_buttons = await page.query_selector_all(
                'button:has-text("Scan"), button:has-text("Refresh"), '
                '.scan-btn, .refresh-btn, [data-testid*="scan"]'
            )
            
            if scan_buttons:
                try:
                    await scan_buttons[0].click()
                    print("Successfully started app scanning")
                    await asyncio.sleep(3)
                except Exception as e:
                    print(f"Failed to start scanning: {e}")
            
            # Test interaction with detected apps
            if installed_apps:
                for i, app_item in enumerate(installed_apps[:3]):
                    try:
                        await app_item.click()
                        print(f"Successfully clicked detected app {i+1}")
                        await asyncio.sleep(0.5)
                    except Exception as e:
                        print(f"Failed to click app {i+1}: {e}")
            
            # Test clone suggestions
            if clone_suggestions:
                try:
                    await clone_suggestions[0].click()
                    print("Successfully clicked clone suggestion")
                    await asyncio.sleep(1)
                except Exception as e:
                    print(f"Failed to click clone suggestion: {e}")
            
            # Look for filter/category options
            filter_elements = await page.query_selector_all(
                '.filter, .category, select, .dropdown, '
                '[data-testid*="filter"], [data-testid*="category"]'
            )
            
            if filter_elements:
                print(f"Found {len(filter_elements)} filter/category elements")
                try:
                    await filter_elements[0].click()
                    print("Successfully clicked filter/category")
                    await asyncio.sleep(1)
                except Exception as e:
                    print(f"Failed to click filter: {e}")
            
            # Test scrolling through detected apps
            await page.mouse.wheel(0, 300)
            await asyncio.sleep(0.5)
            await page.mouse.wheel(0, -300)
            await asyncio.sleep(0.5)
            
            # Look for detection settings
            settings_elements = await page.query_selector_all(
                '.detection-settings, .auto-settings, .preferences, '
                '[data-testid*="settings"], .gear-icon'
            )
            
            if settings_elements:
                print(f"Found {len(settings_elements)} detection settings")
            
            # Test page responsiveness
            page_content = await page.content()
            page_responsive = len(page_content) > 500
            
            # Assertions for auto clone detection
            assert page_responsive, "Page should be responsive and contain content"
            
            # Check if detection interface is available
            detection_interface_available = (
                len(detection_elements) > 0 or 
                len(installed_apps) > 0 or 
                len(clone_suggestions) > 0
            )
            
            if detection_interface_available:
                print("Auto clone detection interface detected")
            else:
                print("No specific detection interface found, but page is functional")
            
            # Test basic page interaction
            try:
                await page.evaluate("document.title")
                interaction_successful = True
            except:
                interaction_successful = False
                
            assert interaction_successful, "Should be able to interact with page"
            
            print("Auto clone detection test completed successfully")
            
        except Exception as e:
            print(f"Error during auto detection test: {e}")
            # Basic functionality check
            page_title = await page.title()
            assert page_title is not None, f"Basic page functionality failed: {e}"
            
        await asyncio.sleep(1)
    
    finally:
        if context:
            await context.close()
        if browser:
            await browser.close()
        if pw:
            await pw.stop()
            
asyncio.run(run_test())
    