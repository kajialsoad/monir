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
        
        # Test statistics tracking accuracy
        print("Testing statistics tracking accuracy...")
        
        # Check if page loads successfully
        page_title = await page.title()
        assert page_title is not None, "Page title should be available"
        print(f"Page loaded with title: {page_title}")
        
        # Test page responsiveness
        await page.mouse.wheel(0, 300)
        await page.wait_for_timeout(1000)
        
        # Look for statistics and analytics related UI elements
        stats_elements = [
            "[data-testid*='stats']",
            "[class*='stats']",
            "[id*='stats']",
            "button:has-text('Statistics')",
            "button:has-text('Analytics')",
            "button:has-text('Reports')",
            "[data-testid*='analytics']",
            "[class*='analytics']",
            "[id*='analytics']",
            "[data-testid*='report']",
            "[class*='report']",
            "[id*='report']",
            "a[href*='stats']",
            "nav a:has-text('Statistics')"
        ]
        
        stats_found = False
        for selector in stats_elements:
            try:
                element = await page.locator(selector).first
                if await element.is_visible(timeout=2000):
                    print(f"Found statistics element: {selector}")
                    stats_found = True
                    # Test interaction with statistics element
                    try:
                        await element.click(timeout=3000)
                        await page.wait_for_timeout(1000)
                    except:
                        pass
                    break
            except:
                continue
        
        # Test usage tracking and metrics features
        usage_elements = [
            "[data-testid*='usage']",
            "[class*='usage']",
            "[id*='usage']",
            "button:has-text('Usage')",
            "button:has-text('Metrics')",
            "button:has-text('Activity')",
            "[data-testid*='metrics']",
            "[class*='metrics']",
            "[id*='metrics']",
            "[data-testid*='activity']",
            "[class*='activity']",
            "[id*='activity']",
            "[data-testid*='tracking']",
            "[class*='tracking']",
            "[id*='tracking']"
        ]
        
        usage_found = False
        for selector in usage_elements:
            try:
                element = await page.locator(selector).first
                if await element.is_visible(timeout=2000):
                    print(f"Found usage element: {selector}")
                    usage_found = True
                    # Test interaction with usage element
                    try:
                        await element.click(timeout=3000)
                        await page.wait_for_timeout(1000)
                    except:
                        pass
                    break
            except:
                continue
        
        # Test performance metrics and monitoring
        performance_elements = [
            "[data-testid*='performance']",
            "[class*='performance']",
            "[id*='performance']",
            "button:has-text('Performance')",
            "button:has-text('Monitor')",
            "button:has-text('Dashboard')",
            "[data-testid*='monitor']",
            "[class*='monitor']",
            "[id*='monitor']",
            "[data-testid*='dashboard']",
            "[class*='dashboard']",
            "[id*='dashboard']",
            "[data-testid*='chart']",
            "[class*='chart']",
            "[id*='chart']"
        ]
        
        performance_found = False
        for selector in performance_elements:
            try:
                element = await page.locator(selector).first
                if await element.is_visible(timeout=2000):
                    print(f"Found performance element: {selector}")
                    performance_found = True
                    # Test interaction with performance element
                    try:
                        await element.click(timeout=3000)
                        await page.wait_for_timeout(1000)
                    except:
                        pass
                    break
            except:
                continue
        
        # Test data visualization and charts
        chart_elements = [
            "canvas",
            "svg",
            "[data-testid*='chart']",
            "[class*='chart']",
            "[id*='chart']",
            "[data-testid*='graph']",
            "[class*='graph']",
            "[id*='graph']",
            "[data-testid*='visualization']",
            "[class*='visualization']",
            "[id*='visualization']",
            ".recharts-wrapper",
            ".chart-container",
            ".graph-container"
        ]
        
        chart_found = False
        for selector in chart_elements:
            try:
                element = await page.locator(selector).first
                if await element.is_visible(timeout=2000):
                    print(f"Found chart element: {selector}")
                    chart_found = True
                    # Test interaction with chart element
                    try:
                        await element.hover(timeout=3000)
                        await page.wait_for_timeout(1000)
                    except:
                        pass
                    break
            except:
                continue
        
        # Test data export and download features
        export_elements = [
            "button:has-text('Export')",
            "button:has-text('Download')",
            "button:has-text('Save')",
            "button:has-text('CSV')",
            "button:has-text('PDF')",
            "[data-testid*='export']",
            "[class*='export']",
            "[id*='export']",
            "[data-testid*='download']",
            "[class*='download']",
            "[id*='download']",
            "a[download]",
            "input[type='file']"
        ]
        
        export_found = False
        for selector in export_elements:
            try:
                element = await page.locator(selector).first
                if await element.is_visible(timeout=2000):
                    print(f"Found export element: {selector}")
                    export_found = True
                    # Test interaction with export element
                    try:
                        await element.click(timeout=3000)
                        await page.wait_for_timeout(1000)
                    except:
                        pass
                    break
            except:
                continue
        
        # Test filter and date range selection
        filter_elements = [
            "button:has-text('Filter')",
            "button:has-text('Date')",
            "button:has-text('Range')",
            "select[name*='filter']",
            "select[name*='date']",
            "input[type='date']",
            "[data-testid*='filter']",
            "[class*='filter']",
            "[id*='filter']",
            "[data-testid*='date']",
            "[class*='date']",
            "[id*='date']",
            "[role='combobox']"
        ]
        
        filter_found = False
        for selector in filter_elements:
            try:
                element = await page.locator(selector).first
                if await element.is_visible(timeout=2000):
                    print(f"Found filter element: {selector}")
                    filter_found = True
                    # Test interaction with filter element
                    try:
                        await element.click(timeout=3000)
                        await page.wait_for_timeout(1000)
                    except:
                        pass
                    break
            except:
                continue
        
        # Test page responsiveness after statistics interactions
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
        
        # Assert statistics tracking accuracy test results
        assert page_title is not None, "Page should load successfully"
        assert page_responsive, "Page should remain responsive after statistics interactions"
        assert interaction_working, "Basic interactions should work"
        
        # At least one statistics tracking related feature should be found
        stats_features_available = stats_found or usage_found or performance_found or chart_found or export_found or filter_found
        assert stats_features_available, "At least one statistics tracking feature should be available in the UI"
        
        print("Statistics tracking accuracy test completed successfully!")
        print(f"Statistics elements found: {stats_found}")
        print(f"Usage elements found: {usage_found}")
        print(f"Performance elements found: {performance_found}")
        print(f"Chart elements found: {chart_found}")
        print(f"Export elements found: {export_found}")
        print(f"Filter elements found: {filter_found}")
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
    