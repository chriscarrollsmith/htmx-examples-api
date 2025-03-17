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
