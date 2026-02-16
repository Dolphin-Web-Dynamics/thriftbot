# Vendoo Automation

Playwright script that automatically lists Thriftbot inventory items on Vendoo.

## How It Works

1. Fetches items from the Thriftbot API (`/api/v1/items?scope=vendoo_ready`)
2. Opens a Chromium browser (you can see it)
3. For each item: navigates to Vendoo's new listing form, fills all fields, uploads images, and saves
4. Marks each item as `listed_with_vendoo: true` in Thriftbot after successful save

## Setup

```bash
cd vendoo-automation
npm install
npx playwright install chromium
cp .env.example .env
```

Edit `.env` with your values:

```
THRIFTBOT_URL=https://thriftbot.smelltherosessecondhand.com
API_TOKEN=your-admin-password
```

## Usage

### List all ready items

```bash
node index.js
```

### List a single item by SKU

```bash
node index.js --sku=THR-001
```

### Dry run (fills forms but doesn't save)

```bash
node index.js --dry-run
```

### Dry run for a single item

```bash
node index.js --dry-run --sku=THR-001
```

## What Happens

1. The script opens a browser window
2. If you're not logged into Vendoo, it pauses and asks you to log in manually
3. For each item it fills: title, description, price, cost, SKU, brand, category, condition, colors, size, weight, dimensions, tags, zip code, notes, and images
4. In live mode, it clicks "Save" and marks the item as listed in Thriftbot
5. In dry-run mode, it fills the form and pauses so you can inspect

## Field Mapping

| Thriftbot | Vendoo |
|-----------|--------|
| general_title | Title |
| description / unified_description | Description |
| listing asking_price | Listing Price |
| acquisition_cost | Cost of Goods |
| sku | SKU |
| brand.name | Brand |
| category.name | Category |
| condition | Condition |
| colors (first) | Primary Color |
| colors (second) | Secondary Color |
| size | US Size |
| weight (lbs) | Package Weight (lbs + oz) |
| length, width, height | Dimensions |
| tags | Tags |
| zip_code | Zip Code |
| notes | Vendoo Internal Notes |
| front_image, back_image, etc. | Photos |
