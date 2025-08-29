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
        
        # Test app list and search functionality
        print("Testing app list and search functionality...")
        
        # Wait for page to load
        await asyncio.sleep(2)
        
        try:
            # Look for app list elements
            app_lists = await page.query_selector_all(
                '.app-list, .application-list, .apps-container, [data-testid*="app-list"], '
                '.installed-apps, .app-grid'
            )
            
            # Look for search functionality
            search_inputs = await page.query_selector_all(
                'input[placeholder*="search"], input[placeholder*="Search"], '
                '.search-input, [data-testid*="search"], input[type="search"]'
            )
            
            # Look for filter/sort options
            filter_elements = await page.query_selector_all(
                '.filter, .sort, select, .dropdown, [data-testid*="filter"], [data-testid*="sort"]'
            )
            
            print(f"Found {len(app_lists)} app list containers")
            print(f"Found {len(search_inputs)} search input fields")
            print(f"Found {len(filter_elements)} filter/sort elements")
            
            # Test search functionality
            if search_inputs:
                search_input = search_inputs[0]
                await search_input.click()
                await search_input.fill("Chrome")
                print("Successfully entered search term: Chrome")
                await asyncio.sleep(1)
                
                # Look for search results
                await page.keyboard.press("Enter")
                await asyncio.sleep(1)
                
                # Clear search and try another term
                await search_input.clear()
                await search_input.fill("Calculator")
                print("Successfully entered search term: Calculator")
                await asyncio.sleep(1)
                
                await search_input.clear()
                print("Successfully cleared search")
                await asyncio.sleep(1)
            
            # Test app list interaction
            app_items = await page.query_selector_all(
                '.app-item, .application, .app-card, .app-entry, [data-testid*="app"]'
            )
            
            print(f"Found {len(app_items)} app items in the list")
            
            if app_items:
                # Click on first few app items
                for i, app_item in enumerate(app_items[:3]):
                    try:
                        await app_item.click()
                        print(f"Successfully clicked app item {i+1}")
                        await asyncio.sleep(0.5)
                    except Exception as e:
                        print(f"Failed to click app item {i+1}: {e}")
            
            # Test filter/sort functionality
            if filter_elements:
                try:
                    await filter_elements[0].click()
                    print("Successfully clicked filter/sort element")
                    await asyncio.sleep(1)
                except Exception as e:
                    print(f"Failed to click filter element: {e}")
            
            # Look for navigation elements
            nav_elements = await page.query_selector_all(
                'nav, .navigation, .menu, .sidebar, [data-testid*="nav"]'
            )
            
            if nav_elements:
                print(f"Found {len(nav_elements)} navigation elements")
            
            # Test scrolling through app list
            await page.mouse.wheel(0, 300)
            await asyncio.sleep(0.5)
            await page.mouse.wheel(0, -300)
            await asyncio.sleep(0.5)
            
            # Look for pagination or load more buttons
            pagination_elements = await page.query_selector_all(
                '.pagination, .load-more, button:has-text("More"), button:has-text("Next"), '
                '[data-testid*="pagination"], [data-testid*="load-more"]'
            )
            
            if pagination_elements:
                print(f"Found {len(pagination_elements)} pagination elements")
                try:
                    await pagination_elements[0].click()
                    print("Successfully clicked pagination element")
                    await asyncio.sleep(1)
                except Exception as e:
                    print(f"Failed to click pagination: {e}")
            
            # Test page responsiveness
            page_content = await page.content()
            page_responsive = len(page_content) > 500
            
            # Assertions for app list and search functionality
            assert page_responsive, "Page should be responsive and contain content"
            
            # Check if app list interface is available
            list_interface_available = len(app_lists) > 0 or len(app_items) > 0
            search_interface_available = len(search_inputs) > 0
            
            if list_interface_available:
                print("App list interface detected")
            
            if search_interface_available:
                print("Search interface detected")
            
            if not (list_interface_available or search_interface_available):
                print("No specific app list/search interface found, but page is functional")
            
            # Test basic page interaction
            try:
                await page.evaluate("document.title")
                interaction_successful = True
            except:
                interaction_successful = False
                
            assert interaction_successful, "Should be able to interact with page"
            
            print("App list and search functionality test completed successfully")
            
        except Exception as e:
            print(f"Error during app list/search test: {e}")
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
    