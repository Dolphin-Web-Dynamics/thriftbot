#!/usr/bin/env node

require("dotenv").config();
const { chromium } = require("playwright");
const fs = require("fs");
const path = require("path");
const os = require("os");
const https = require("https");
const http = require("http");

// --- Configuration ---

const THRIFTBOT_URL = process.env.THRIFTBOT_URL || "https://thriftbot.smelltherosessecondhand.com";
const API_TOKEN = process.env.API_TOKEN;
const VENDOO_NEW_ITEM_URL = "https://web.vendoo.co/app/item/new?marketplace=general";

const DRY_RUN = process.argv.includes("--dry-run");
const SINGLE_SKU = process.argv.find((a) => a.startsWith("--sku="))?.split("=")[1];

// Condition mapping: Thriftbot enum → Vendoo dropdown label
const CONDITION_MAP = {
  new_with_tags: "New with Tags",
  new_without_tags: "New without Tags",
  excellent: "Excellent / Like New",
  good: "Good",
  fair: "Fair",
};

// --- API Client ---

async function fetchItems() {
  const url = `${THRIFTBOT_URL}/api/v1/items?scope=vendoo_ready`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${API_TOKEN}` },
  });
  if (!res.ok) throw new Error(`API error: ${res.status} ${res.statusText}`);
  const data = await res.json();
  return data.items;
}

async function fetchItem(id) {
  const url = `${THRIFTBOT_URL}/api/v1/items/${id}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${API_TOKEN}` },
  });
  if (!res.ok) throw new Error(`API error: ${res.status} ${res.statusText}`);
  const data = await res.json();
  return data.item;
}

async function markAsListed(id) {
  const url = `${THRIFTBOT_URL}/api/v1/items/${id}/mark_listed`;
  const res = await fetch(url, {
    method: "PATCH",
    headers: { Authorization: `Bearer ${API_TOKEN}` },
  });
  if (!res.ok) throw new Error(`Failed to mark item ${id} as listed: ${res.status}`);
}

// --- Image Helpers ---

function downloadFile(url, destPath) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith("https") ? https : http;
    client.get(url, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return downloadFile(res.headers.location, destPath).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) {
        return reject(new Error(`Download failed: ${res.statusCode} for ${url}`));
      }
      const stream = fs.createWriteStream(destPath);
      res.pipe(stream);
      stream.on("finish", () => { stream.close(); resolve(destPath); });
      stream.on("error", reject);
    }).on("error", reject);
  });
}

async function downloadImages(imageUrls) {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "vendoo-images-"));
  const paths = [];
  for (let i = 0; i < imageUrls.length; i++) {
    const ext = imageUrls[i].match(/\.(jpe?g|png|heic|heif|mp4|mov)/i)?.[0] || ".jpg";
    const filePath = path.join(tmpDir, `image_${i}${ext}`);
    try {
      await downloadFile(imageUrls[i], filePath);
      paths.push(filePath);
    } catch (err) {
      console.warn(`  ⚠ Failed to download image ${i}: ${err.message}`);
    }
  }
  return { paths, tmpDir };
}

// --- Form Filling ---

async function fillTextField(page, testId, value) {
  if (!value) return;
  try {
    const field = page.locator(`[data-testid="${testId}"]`);
    await field.waitFor({ timeout: 3000 });
    await field.click();
    await field.fill(String(value));
  } catch (err) {
    console.warn(`  ⚠ Could not fill ${testId}: ${err.message}`);
  }
}

async function fillDropdown(page, ariaLabel, value) {
  if (!value) return;
  try {
    const dropdown = page.locator(`[aria-label="${ariaLabel}"]`);
    await dropdown.waitFor({ timeout: 3000 });
    await dropdown.click();
    await dropdown.fill(value);
    // Wait for dropdown options to appear, then select the first match
    await page.waitForTimeout(500);
    const option = page.locator(`[class*="option"]`).filter({ hasText: value }).first();
    const optionVisible = await option.isVisible().catch(() => false);
    if (optionVisible) {
      await option.click();
    } else {
      // Try pressing Enter to select the typed value
      await dropdown.press("Enter");
    }
  } catch (err) {
    console.warn(`  ⚠ Could not fill dropdown "${ariaLabel}" with "${value}": ${err.message}`);
  }
}

async function fillTags(page, tags) {
  if (!tags) return;
  try {
    const container = page.locator(`[data-testid="generalDetails.tags-multi-selector-container"]`);
    await container.waitFor({ timeout: 3000 });
    const input = container.locator("input").first();
    const tagList = tags.split(",").map((t) => t.trim()).filter(Boolean);
    for (const tag of tagList) {
      await input.fill(tag);
      await input.press("Enter");
      await page.waitForTimeout(200);
    }
  } catch (err) {
    console.warn(`  ⚠ Could not fill tags: ${err.message}`);
  }
}

async function uploadImages(page, imagePaths) {
  if (!imagePaths.length) return;
  try {
    const fileInput = page.locator(`[data-testid="imageInput"]`);
    await fileInput.waitFor({ timeout: 5000 });
    await fileInput.setInputFiles(imagePaths);
    // Wait for uploads to process
    await page.waitForTimeout(2000);
  } catch (err) {
    console.warn(`  ⚠ Could not upload images: ${err.message}`);
  }
}

async function fillVendooForm(page, item) {
  console.log(`  Filling form for: ${item.title || item.sku}`);

  // Simple text fields
  await fillTextField(page, "generalDetails.title", item.title);
  await fillTextField(page, "generalDetails.description", item.description);
  await fillTextField(page, "generalDetails.price", item.price);
  await fillTextField(page, "generalDetails.cost", item.cost);
  await fillTextField(page, "generalDetails.sku", item.sku);
  await fillTextField(page, "generalDetails.quantity", 1);
  await fillTextField(page, "generalDetails.zipCode", item.zip_code);

  // Weight conversion (lbs → pounds + ounces)
  if (item.weight_lbs) {
    const pounds = Math.floor(item.weight_lbs);
    const ounces = Math.round((item.weight_lbs - pounds) * 16);
    await fillTextField(page, "generalDetails.weight.pounds", pounds);
    await fillTextField(page, "generalDetails.weight.ounces", ounces);
  }

  // Dimensions
  await fillTextField(page, "generalDetails.dimensions.length", item.length);
  await fillTextField(page, "generalDetails.dimensions.width", item.width);
  await fillTextField(page, "generalDetails.dimensions.height", item.height);

  // Dropdowns
  await fillDropdown(page, "Brand", item.brand);
  await fillDropdown(page, "Category Selector for vendoo", item.category);
  await fillDropdown(page, "Condition", CONDITION_MAP[item.condition] || item.condition);

  // Colors (split if comma-separated)
  if (item.colors) {
    const colors = item.colors.split(",").map((c) => c.trim());
    await fillDropdown(page, "Primary Color", colors[0]);
    if (colors[1]) {
      await fillDropdown(page, "Secondary Color", colors[1]);
    }
  }

  // Size
  await fillDropdown(page, "US Size", item.size);

  // Tags
  await fillTags(page, item.tags);

  // Notes
  await fillTextField(page, "generalDetails.notes", item.notes);
}

// --- Main ---

async function main() {
  if (!API_TOKEN) {
    console.error("Error: API_TOKEN is required. Set it in .env or as environment variable.");
    process.exit(1);
  }

  console.log("=== Vendoo Automation ===");
  console.log(`Thriftbot: ${THRIFTBOT_URL}`);
  console.log(`Mode: ${DRY_RUN ? "DRY RUN (will not save)" : "LIVE"}`);
  console.log();

  // Fetch items from Thriftbot API
  console.log("Fetching items from Thriftbot...");
  let items = await fetchItems();

  if (SINGLE_SKU) {
    items = items.filter((i) => i.sku === SINGLE_SKU);
    if (!items.length) {
      console.error(`No vendoo-ready item found with SKU: ${SINGLE_SKU}`);
      process.exit(1);
    }
  }

  if (!items.length) {
    console.log("No items ready for Vendoo listing. All done!");
    return;
  }

  console.log(`Found ${items.length} item(s) to list.\n`);

  // Launch browser
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({ viewport: { width: 1400, height: 900 } });
  const page = await context.newPage();

  // Navigate to Vendoo and check login
  console.log("Opening Vendoo...");
  await page.goto("https://web.vendoo.co/app/inventory", { waitUntil: "networkidle" });

  // Check if we need to log in
  const currentUrl = page.url();
  if (currentUrl.includes("/login") || currentUrl.includes("/register")) {
    console.log("\n⏸  Please log into Vendoo in the browser window.");
    console.log("   Press Enter here once you're logged in...\n");
    await new Promise((resolve) => {
      process.stdin.once("data", resolve);
    });
  }

  // Process each item
  const results = { success: 0, failed: 0, skipped: 0 };

  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    console.log(`\n[${i + 1}/${items.length}] Processing: ${item.sku} - ${item.title}`);

    try {
      // Navigate to new item form
      await page.goto(VENDOO_NEW_ITEM_URL, { waitUntil: "networkidle", timeout: 30000 });
      await page.waitForTimeout(1000);

      // Download and upload images
      let tmpDir = null;
      if (item.image_urls?.length) {
        console.log(`  Downloading ${item.image_urls.length} image(s)...`);
        const downloaded = await downloadImages(item.image_urls);
        if (downloaded.paths.length) {
          await uploadImages(page, downloaded.paths);
        }
        tmpDir = downloaded.tmpDir;
      }

      // Fill the form
      await fillVendooForm(page, item);

      if (DRY_RUN) {
        console.log("  ✓ Form filled (dry run — not saving)");
        console.log("  Pausing 3 seconds so you can inspect...");
        await page.waitForTimeout(3000);
        results.success++;
      } else {
        // Click save
        const saveBtn = page.locator(`[data-testid="save-item-button"]`);
        await saveBtn.waitFor({ timeout: 5000 });
        await saveBtn.click();

        // Wait for save to complete (look for success indicator or URL change)
        await page.waitForTimeout(3000);

        // Mark as listed in Thriftbot
        await markAsListed(item.id);
        console.log("  ✓ Listed on Vendoo and marked in Thriftbot");
        results.success++;
      }

      // Cleanup temp images
      if (tmpDir) {
        fs.rmSync(tmpDir, { recursive: true, force: true });
      }
    } catch (err) {
      console.error(`  ✗ Failed: ${err.message}`);
      results.failed++;
    }
  }

  // Summary
  console.log("\n=== Results ===");
  console.log(`✓ Success: ${results.success}`);
  console.log(`✗ Failed:  ${results.failed}`);
  console.log(`○ Skipped: ${results.skipped}`);

  if (!DRY_RUN) {
    console.log("\nClosing browser in 5 seconds...");
    await page.waitForTimeout(5000);
  } else {
    console.log("\nDry run complete. Closing browser in 3 seconds...");
    await page.waitForTimeout(3000);
  }

  await browser.close();
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
