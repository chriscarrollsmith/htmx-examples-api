# HTMX Examples Scraping Workflow

This document outlines the steps to scrape HTML examples from the htmx.org website. These examples demonstrate various UI patterns implemented with HTMX.

## Prerequisites

- Bash shell environment
- `wget` command-line tool installed

## Steps

1. **Create the scraping script**

   Create a file named `workflow/scrape_htmx.sh` with the following content:

   ```bash
   #!/bin/bash

   # Create directories if they don't exist
   mkdir -p examples
   mkdir -p artifacts

   # Download the examples page
   echo "Downloading HTMX examples page..."
   wget -q -O artifacts/htmx_examples_page.html https://htmx.org/examples/

   # Download all examples
   echo "Downloading HTMX examples..."

   # Extract example links and download them
   echo "Extracting example links and downloading them..."
   grep -o '<a href="https://htmx.org/examples/[^"]*/">[^<]*</a>' artifacts/htmx_examples_page.html | 
   while read -r line; do
     url=$(echo "$line" | grep -o 'https://htmx.org/examples/[^"]*/')
     name=$(echo "$url" | sed 's|https://htmx.org/examples/||' | sed 's|/$||')
     echo "Downloading $name..."
     wget -q -O examples/${name}.html ${url}
   done

   # If the automatic extraction fails or misses examples, fall back to the manual list
   # Check if we have at least 27 examples
   example_count=$(ls -1 examples/*.html 2>/dev/null | wc -l)
   if [ "$example_count" -lt 27 ]; then
     echo "Automatic extraction found fewer than expected examples. Using manual list as fallback..."
     
     # UI Patterns
     wget -q -O examples/click-to-edit.html https://htmx.org/examples/click-to-edit/
     wget -q -O examples/bulk-update.html https://htmx.org/examples/bulk-update/
     wget -q -O examples/click-to-load.html https://htmx.org/examples/click-to-load/
     wget -q -O examples/delete-row.html https://htmx.org/examples/delete-row/
     wget -q -O examples/edit-row.html https://htmx.org/examples/edit-row/
     wget -q -O examples/lazy-load.html https://htmx.org/examples/lazy-load/
     wget -q -O examples/inline-validation.html https://htmx.org/examples/inline-validation/
     wget -q -O examples/infinite-scroll.html https://htmx.org/examples/infinite-scroll/
     wget -q -O examples/active-search.html https://htmx.org/examples/active-search/
     wget -q -O examples/progress-bar.html https://htmx.org/examples/progress-bar/
     wget -q -O examples/value-select.html https://htmx.org/examples/value-select/
     wget -q -O examples/animations.html https://htmx.org/examples/animations/
     wget -q -O examples/file-upload.html https://htmx.org/examples/file-upload/
     wget -q -O examples/file-upload-input.html https://htmx.org/examples/file-upload-input/
     wget -q -O examples/reset-user-input.html https://htmx.org/examples/reset-user-input/

     # Dialog Examples
     wget -q -O examples/dialogs.html https://htmx.org/examples/dialogs/
     wget -q -O examples/modal-uikit.html https://htmx.org/examples/modal-uikit/
     wget -q -O examples/modal-bootstrap.html https://htmx.org/examples/modal-bootstrap/
     wget -q -O examples/modal-custom.html https://htmx.org/examples/modal-custom/

     # Advanced Examples
     wget -q -O examples/tabs-hateoas.html https://htmx.org/examples/tabs-hateoas/
     wget -q -O examples/tabs-javascript.html https://htmx.org/examples/tabs-javascript/
     wget -q -O examples/keyboard-shortcuts.html https://htmx.org/examples/keyboard-shortcuts/
     wget -q -O examples/sortable.html https://htmx.org/examples/sortable/
     wget -q -O examples/update-other-content.html https://htmx.org/examples/update-other-content/
     wget -q -O examples/confirm.html https://htmx.org/examples/confirm/
     wget -q -O examples/async-auth.html https://htmx.org/examples/async-auth/
     wget -q -O examples/web-components.html https://htmx.org/examples/web-components/
     wget -q -O examples/move-before.html https://htmx.org/examples/move-before/
   fi

   # Count and list the downloaded examples
   example_count=$(ls -1 examples/*.html 2>/dev/null | wc -l)
   echo "All examples downloaded successfully to the 'examples' directory."
   echo "Total examples downloaded: $example_count"
   ```

   This script combines both approaches:
   
   1. It first attempts to automatically extract and download examples from the htmx.org examples page
   2. If fewer than 27 examples are found (indicating the automatic extraction might have missed some), it falls back to a manual list of examples
   3. Any intermediate files (like the downloaded examples page) are stored in the `artifacts` directory

2. **Make the script executable**

   ```bash
   chmod +x workflow/scrape_htmx.sh
   ```

3. **Run the script to download all examples**

   ```bash
   ./workflow/scrape_htmx.sh
   ```

4. **Verify the downloaded examples**

   The script will output the total number of examples downloaded. You can also manually check:

   ```bash
   ls -la examples | wc -l
   ls -la examples
   ```

   You should see 27-28 HTML files in the examples directory, corresponding to all the HTMX examples from htmx.org.

## Example Categories

The downloaded examples are organized into the following categories:

1. **UI Patterns** (15 examples)
   - Click To Edit, Bulk Update, Click To Load, etc.

2. **Dialog Examples** (4 examples)
   - Browser Dialogs, UIKit Modals, Bootstrap Modals, Custom Modals

3. **Advanced Examples** (8-9 examples)
   - Tabs (HATEOAS), Tabs (JavaScript), Keyboard Shortcuts, etc.

## Next Steps

After successfully downloading all the examples, proceed to the next step in the workflow: extracting structured data from the HTML files.
