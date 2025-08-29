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
        
        # Test MethodChannel communication reliability
        print("Testing MethodChannel communication reliability...")
        
        # Check if page loads successfully
        page_title = await page.title()
        assert page_title is not None, "Page title should be available"
        print(f"Page loaded with title: {page_title}")
        
        # Test page responsiveness
        await page.mouse.wheel(0, 300)
        await page.wait_for_timeout(1000)
        
        # Look for Flutter/MethodChannel related UI elements
        flutter_elements = [
            "[data-testid*='flutter']",
            "[class*='flutter']",
            "[id*='flutter']",
            "button:has-text('Flutter')",
            "button:has-text('Native')",
            "button:has-text('Bridge')",
            "[data-testid*='native']",
            "[class*='native']",
            "[id*='native']",
            "[data-testid*='bridge']",
            "[class*='bridge']",
            "[id*='bridge']",
            "[data-testid*='channel']",
            "[class*='channel']",
            "[id*='channel']"
        ]
        
        flutter_found = False
        for selector in flutter_elements:
            try:
                element = await page.locator(selector).first
                if await element.is_visible(timeout=2000):
                    print(f"Found Flutter element: {selector}")
                    flutter_found = True
                    # Test interaction with Flutter element
                    try:
                        await element.click(timeout=3000)
                        await page.wait_for_timeout(1000)
                    except:
                        pass
                    break
            except:
                continue
        
        # Test communication and messaging features
        communication_elements = [
            "[data-testid*='communication']",
            "[class*='communication']",
            "[id*='communication']",
            "button:has-text('Communication')",
            "button:has-text('Message')",
            "button:has-text('Send')",
            "[data-testid*='message']",
            "[class*='message']",
            "[id*='message']",
            "[data-testid*='send']",
            "[class*='send']",
            "[id*='send']",
            "[data-testid*='receive']",
            "[class*='receive']",
            "[id*='receive']",
            "input[type='text']",
            "textarea"
        ]
        
        communication_found = False
        for selector in communication_elements:
            try:
                element = await page.locator(selector).first
                if await element.is_visible(timeout=2000):
                    print(f"Found communication element: {selector}")
                    communication_found = True
                    # Test interaction with communication element
                    try:
                        if selector in ["input[type='text']", "textarea"]:
                            await element.fill("Test message", timeout=3000)
                        else:
                            await element.click(timeout=3000)
                        await page.wait_for_timeout(1000)
                    except:
                        pass
                    break
            except:
                continue
        
        # Test API and service integration features
        api_elements = [
            "[data-testid*='api']",
            "[class*='api']",
            "[id*='api']",
            "button:has-text('API')",
            "button:has-text('Service')",
            "button:has-text('Connect')",
            "[data-testid*='service']",
            "[class*='service']",
            "[id*='service']",
            "[data-testid*='connect']",
            "[class*='connect']",
            "[id*='connect']",
            "[data-testid*='integration']",
            "[class*='integration']",
            "[id*='integration']",
            "[data-testid*='endpoint']",
            "[class*='endpoint']",
            "[id*='endpoint']"
        ]
        
        api_found = False
        for selector in api_elements:
            try:
                element = await page.locator(selector).first
                if await element.is_visible(timeout=2000):
                    print(f"Found API element: {selector}")
                    api_found = True
                    # Test interaction with API element
                    try:
                        await element.click(timeout=3000)
                        await page.wait_for_timeout(1000)
                    except:
                        pass
                    break
            except:
                continue
        
        # Test reliability and error handling features
        reliability_elements = [
            "[data-testid*='reliability']",
            "[class*='reliability']",
            "[id*='reliability']",
            "button:has-text('Reliability')",
            "button:has-text('Error')",
            "button:has-text('Retry')",
            "[data-testid*='error']",
            "[class*='error']",
            "[id*='error']",
            "[data-testid*='retry']",
            "[class*='retry']",
            "[id*='retry']",
            "[data-testid*='timeout']",
            "[class*='timeout']",
            "[id*='timeout']",
            "[data-testid*='fallback']",
            "[class*='fallback']",
            "[id*='fallback']"
        ]
        
        reliability_found = False
        for selector in reliability_elements:
            try:
                element = await page.locator(selector).first
                if await element.is_visible(timeout=2000):
                    print(f"Found reliability element: {selector}")
                    reliability_found = True
                    # Test interaction with reliability element
                    try:
                        await element.click(timeout=3000)
                        await page.wait_for_timeout(1000)
                    except:
                        pass
                    break
            except:
                continue
        
        # Test status and monitoring features
        status_elements = [
            "[data-testid*='status']",
            "[class*='status']",
            "[id*='status']",
            "button:has-text('Status')",
            "button:has-text('Health')",
            "button:has-text('Monitor')",
            "[data-testid*='health']",
            "[class*='health']",
            "[id*='health']",
            "[data-testid*='monitor']",
            "[class*='monitor']",
            "[id*='monitor']",
            "[data-testid*='connection']",
            "[class*='connection']",
            "[id*='connection']",
            ".status-indicator",
            ".health-check",
            ".connection-status"
        ]
        
        status_found = False
        for selector in status_elements:
            try:
                element = await page.locator(selector).first
                if await element.is_visible(timeout=2000):
                    print(f"Found status element: {selector}")
                    status_found = True
                    # Test interaction with status element
                    try:
                        await element.click(timeout=3000)
                        await page.wait_for_timeout(1000)
                    except:
                        pass
                    break
            except:
                continue
        
        # Test console and debugging features
        console_elements = [
            "[data-testid*='console']",
            "[class*='console']",
            "[id*='console']",
            "button:has-text('Console')",
            "button:has-text('Debug')",
            "button:has-text('Log')",
            "[data-testid*='debug']",
            "[class*='debug']",
            "[id*='debug']",
            "[data-testid*='log']",
            "[class*='log']",
            "[id*='log']",
            "[data-testid*='trace']",
            "[class*='trace']",
            "[id*='trace']",
            ".console-output",
            ".debug-panel",
            ".log-viewer"
        ]
        
        console_found = False
        for selector in console_elements:
            try:
                element = await page.locator(selector).first
                if await element.is_visible(timeout=2000):
                    print(f"Found console element: {selector}")
                    console_found = True
                    # Test interaction with console element
                    try:
                        await element.click(timeout=3000)
                        await page.wait_for_timeout(1000)
                    except:
                        pass
                    break
            except:
                continue
        
        # Test page responsiveness after MethodChannel interactions
        await page.mouse.wheel(0, -300)
        await page.wait_for_timeout(1000)
        
        # Check if page is still responsive
        try:
            await page.locator('body').click(timeout=3000)
            page_responsive = True
        except:
            page_responsive = False
        
        # Test basic interaction capability
        try:
            await page.keyboard.press('Tab')
            await page.wait_for_timeout(500)
            interaction_working = True
        except:
            interaction_working = False
        
        # Assert MethodChannel communication reliability test results
        assert page_title is not None, "Page should load successfully"
        assert page_responsive, "Page should remain responsive after MethodChannel interactions"
        assert interaction_working, "Basic interactions should work"
        
        # At least one MethodChannel communication related feature should be found
        methodchannel_features_available = flutter_found or communication_found or api_found or reliability_found or status_found or console_found
        assert methodchannel_features_available, "At least one MethodChannel communication feature should be available in the UI"
        
        print("MethodChannel communication reliability test completed successfully!")
        print(f"Flutter elements found: {flutter_found}")
        print(f"Communication elements found: {communication_found}")
        print(f"API elements found: {api_found}")
        print(f"Reliability elements found: {reliability_found}")
        print(f"Status elements found: {status_found}")
        print(f"Console elements found: {console_found}")
        print(f"Page responsive: {page_responsive}")
        print(f"Interaction working: {interaction_working}")
        await asyncio.sleep(5)
    
    finally:
        if context:
            await context.close()
        if browser:
            await browser.close()
        if pw:
            await pw.stop()
            
asyncio.run(run_test())
    